import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:graphview/graphview.dart';
import '../models/family_member.dart';
import 'add_family_member.dart';

class FamilyTreeScreen extends StatefulWidget {
  const FamilyTreeScreen({Key? key}) : super(key: key);

  @override
  _FamilyTreeScreenState createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends State<FamilyTreeScreen> with SingleTickerProviderStateMixin {
  final _familyBox = Hive.box<FamilyMember>('familyTree');
  static const String USER_ID = "user_self";  // Constant ID for the user
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Graph related properties
  late Graph graph;
  late BuchheimWalkerConfiguration builder;
  late GraphView graphView;

  @override
  void initState() {
    super.initState();
    _fixGenerationLevels();
    
    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    
    // Initialize the graph
    _setupGraphView();
    
    // Start animation after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupGraphView() {
    // Create a new graph instance instead of clearing
    graph = Graph()..isTree = true;
    
    builder = BuchheimWalkerConfiguration()
      ..siblingSeparation = 100
      ..levelSeparation = 150
      ..subtreeSeparation = 150
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;
    
    _buildGraph();
    
    graphView = GraphView(
      graph: graph,
      algorithm: BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
      paint: Paint()
        ..color = Colors.blue
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
      builder: (Node node) {
        // Get the FamilyMember from the node's value
        final member = node.key!.value as FamilyMember;
        
        // Create a different appearance for the user (self)
        bool isSelf = member.id == USER_ID;
        
        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelf ? Colors.blue : _getColorByGeneration(member.generationLevel),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${member.firstName} ${member.lastName}",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isSelf ? 18 : 16,
                      ),
                    ),
                    if (member.relationshipType.isNotEmpty && !isSelf)
                      Text(
                        member.relationshipType,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _buildGraph() {
    // No need to clear, as we create a new graph instance in _setupGraphView
    
    // Ensure the user exists
    _ensureUserExists();
    
    // Create a map of all family members by ID for easier access
    Map<String, FamilyMember> membersById = {};
    Map<int, List<String>> membersByGeneration = {};
    
    // Add all members to the maps
    for (var member in _familyBox.values) {
      membersById[member.id] = member;
      membersByGeneration.putIfAbsent(member.generationLevel, () => []).add(member.id);
    }
    
    // Get the user node
    FamilyMember userMember = membersById[USER_ID]!;
    Node userNode = Node.Id(userMember);
    
    // Add the user node to the graph
    graph.addNode(userNode);
    
    // Track added nodes to avoid duplicates
    Set<String> addedNodeIds = {USER_ID};
    
    // Iterate through generations, starting from the user's parents
    for (int level = 2; level <= 5; level++) {
      if (membersByGeneration.containsKey(level)) {
        for (String memberId in membersByGeneration[level]!) {
          if (!addedNodeIds.contains(memberId)) {
            // Add the node
            Node newNode = Node.Id(membersById[memberId]!);
            graph.addNode(newNode);
            addedNodeIds.add(memberId);
            
            // Connect to parent (determine the connection based on relationship)
            // For demonstration, connect all ancestors to the user directly
            // In a real app, you would use parentId to create the actual hierarchy
            graph.addEdge(userNode, newNode);
          }
        }
      }
    }
  }

  Color _getColorByGeneration(int level) {
    switch (level) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.teal;
      case 3:
        return Colors.purple;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  /// Adds the user as the central person in the family tree if not already present
  void _ensureUserExists() {
    bool userExists = false;
    
    // Check if user already exists
    for (var member in _familyBox.values) {
      if (member.id == USER_ID) {
        userExists = true;
        break;
      }
    }
    
    // If user doesn't exist, add them to the database
    if (!userExists) {
      // Create empty lists for the encrypted security questions and answers
      List<String> emptyEncryptedList = [];
      
      // Create a basic user record
      final user = FamilyMember(
        id: USER_ID,
        firstName: "Your",
        middleName: "",
        lastName: "Name",
        birthDate: "",
        encryptedSecurityQuestions: emptyEncryptedList,
        encryptedSecurityAnswers: emptyEncryptedList,
        encryptedHashedData: "",
        relationshipType: "Self",
        generationLevel: 1,
        parentId: null,
      );
      
      _familyBox.put(USER_ID, user);
    } else {
      // Update existing user to make sure generation level is correct
      var existingUser = _familyBox.values.firstWhere((m) => m.id == USER_ID);
      if (existingUser.generationLevel != 1) {
        var updatedUser = existingUser.copyWith(newGenerationLevel: 1);
        _familyBox.put(USER_ID, updatedUser);
      }
    }
  }

  void _fixGenerationLevels() {
    // First ensure user exists
    _ensureUserExists();
    
    // Fix generation levels by relationship type
    for (var member in _familyBox.values) {
      if (member.id != USER_ID) {
        String relationship = member.relationshipType.toLowerCase();
        int level;
        
        // Assign generation levels based on relationship
        if (relationship.contains('parent') || 
            relationship.contains('father') || 
            relationship.contains('mother')) {
          level = 2; // Parents are level 2
        } else if (relationship.contains('grand') && 
                  (relationship.contains('parent') || 
                   relationship.contains('father') || 
                   relationship.contains('mother'))) {
          level = 3; // Grandparents are level 3
        } else if (relationship.contains('great') && 
                  relationship.contains('grand') &&
                  !relationship.contains('great great')) {
          level = 4; // Great grandparents are level 4
        } else if (relationship.contains('great great')) {
          level = 5; // Great great grandparents are level 5
        } else {
          // Default to level 2 if relationship is not recognized
          level = 2;
        }
        
        // Update member's generation level if needed
        if (member.generationLevel != level) {
          var updatedMember = member.copyWith(newGenerationLevel: level);
          _familyBox.put(member.key, updatedMember);
        }
      }
    }
    
    setState(() {});  // Refresh UI
  }

  void _navigateToAddFamilyMember() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddFamilyMemberScreen()),
    ).then((_) {
      setState(() {
        _setupGraphView();
        _animationController.reset();
        _animationController.forward();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Family Tree"),
        backgroundColor: Colors.blue,
        actions: [
          // Only show refresh button when tree is not empty
          if (_familyBox.length > 1)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _setupGraphView();
                  _animationController.reset();
                  _animationController.forward();
                });
              },
              tooltip: 'Refresh Tree',
            ),
          // Only show add button in AppBar when tree is not empty
          if (_familyBox.length > 1)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: _navigateToAddFamilyMember,
              tooltip: 'Add Family Member',
            ),
        ],
      ),
      backgroundColor: Colors.white,
      body: _familyBox.length <= 1 
          ? _buildEmptyAncestorsMessage(context)
          : _buildTreeView(context),
      // Removed the floating action button
    );
  }

  Widget _buildTreeView(BuildContext context) {
    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(50),
      minScale: 0.1,
      maxScale: 2.0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: graphView,
        ),
      ),
    );
  }

  Widget _buildEmptyAncestorsMessage(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.family_restroom, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            "Your family tree is empty",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Add an ancestors to visualize your family tree",
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          ElevatedButton(
            onPressed: _navigateToAddFamilyMember,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            ),
            child: const Text("Add Family Member"),
          ),
        ],
      ),
    );
  }
}
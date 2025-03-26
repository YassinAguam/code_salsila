import 'package:flutter/material.dart';
import 'add_family_member.dart';
import 'generate_qr.dart';
import 'scan_qr.dart';
import 'family_tree_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kinship App"),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // User welcome section
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome back,",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "User_3321",
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Main content - Scrollable area for actions
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  children: [
                    _buildActionTile(
                      icon: Icons.person_add_alt_1,
                      label: "Add Ancestor",
                      context: context,
                      screen: const AddFamilyMemberScreen(),
                      color: Colors.blue,
                    ),
                    _buildActionTile(
                      icon: Icons.qr_code,
                      label: "Generate QR Code",
                      context: context,
                      screen: const GenerateQRScreen(),
                      color: Colors.green,
                    ),
                    _buildActionTile(
                      icon: Icons.qr_code_scanner,
                      label: "Scan QR Code",
                      context: context,
                      screen: const ScanQRScreen(),
                      color: Colors.orange,
                    ),
                    _buildActionTile(
                      icon: Icons.family_restroom,
                      label: "View Family Tree",
                      context: context,
                      screen: const FamilyTreeScreen(),
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Modern tile-based action button
  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required BuildContext context,
    required Widget screen,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
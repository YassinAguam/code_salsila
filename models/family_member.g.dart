// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_member.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FamilyMemberAdapter extends TypeAdapter<FamilyMember> {
  @override
  final int typeId = 0;

  @override
  FamilyMember read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FamilyMember(
      id: fields[0] as String,
      firstName: fields[1] as String,
      middleName: fields[2] as String,
      lastName: fields[3] as String,
      birthDate: fields[4] as String,
      encryptedSecurityQuestions: (fields[5] as List).cast<String>(),
      encryptedSecurityAnswers: (fields[6] as List).cast<String>(),
      encryptedHashedData: fields[7] as String,
      relationshipType: fields[10] as String,
      generationLevel: fields[11] as int,
      parentId: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FamilyMember obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.firstName)
      ..writeByte(2)
      ..write(obj.middleName)
      ..writeByte(3)
      ..write(obj.lastName)
      ..writeByte(4)
      ..write(obj.birthDate)
      ..writeByte(5)
      ..write(obj.encryptedSecurityQuestions)
      ..writeByte(6)
      ..write(obj.encryptedSecurityAnswers)
      ..writeByte(7)
      ..write(obj.encryptedHashedData)
      ..writeByte(8)
      ..write(obj._encryptionKey)
      ..writeByte(9)
      ..write(obj.parentId)
      ..writeByte(10)
      ..write(obj.relationshipType)
      ..writeByte(11)
      ..write(obj.generationLevel);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilyMemberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

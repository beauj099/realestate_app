import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/auth/data/models/agent_profile.dart';

void main() {
  group('AgentProfile.splitName', () {
    test('splits at the first space, keeping multi-word surnames', () {
      expect(AgentProfile.splitName('Jan van der Merwe'), (
        'Jan',
        'van der Merwe',
      ));
    });

    test('a single name has no surname', () {
      expect(AgentProfile.splitName('  Dylan '), ('Dylan', ''));
    });
  });

  test('fullName joins first and last name', () {
    const p = AgentProfile(firstName: 'Jane', lastName: 'Doe');
    expect(p.fullName, 'Jane Doe');
    expect(const AgentProfile(firstName: 'Dylan').fullName, 'Dylan');
  });

  test('fromJson reads caches written before the name was split', () {
    final p = AgentProfile.fromJson({'fullName': 'Jane Doe'});
    expect(p.firstName, 'Jane');
    expect(p.lastName, 'Doe');
  });

  group('AgentProfile.fromApi', () {
    final dto = {
      'id': 7,
      'displayName': 'Mary Anne Smith',
      'email': 'mary@example.com',
      'mobile': '0821234567',
      'agencyName': 'Seeff Property Group',
      'agencyRegistrationNumber': null,
      'licenceNumber': null,
      'role': 'Agent',
    };

    test('maps the DTO, treating null numbers as blank', () {
      final p = AgentProfile.fromApi(dto);
      expect(p.email, 'mary@example.com');
      expect(p.mobile, '0821234567');
      expect(p.agencyName, 'Seeff Property Group');
      expect(p.agencyRegistrationNumber, '');
    });

    test('keeps a cached first/last split that spells the same name', () {
      const cached = AgentProfile(firstName: 'Mary Anne', lastName: 'Smith');
      final p = AgentProfile.fromApi(dto, cached: cached);
      expect(p.firstName, 'Mary Anne');
      expect(p.lastName, 'Smith');
    });

    test('re-splits when the name changed elsewhere', () {
      const cached = AgentProfile(firstName: 'Old', lastName: 'Name');
      final p = AgentProfile.fromApi(dto, cached: cached);
      expect(p.firstName, 'Mary');
      expect(p.lastName, 'Anne Smith');
    });

    test('drops a cached agency slug once the agency name changed', () {
      const cached = AgentProfile(agencyName: 'RE/MAX', agencySlug: 'remax');
      expect(AgentProfile.fromApi(dto, cached: cached).agencySlug, isNull);
    });
  });

  test('toApiJson sends blank optional numbers as null', () {
    const p = AgentProfile(
      firstName: 'Jane',
      lastName: 'Doe',
      email: 'jane@example.com',
      mobile: '0821234567',
      agencyName: 'Bay Realty',
    );
    final json = p.toApiJson();
    expect(json['displayName'], 'Jane Doe');
    expect(json['agencyRegistrationNumber'], isNull);
    expect(json['licenceNumber'], isNull);
  });
}

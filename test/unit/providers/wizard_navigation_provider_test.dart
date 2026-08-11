import 'package:flutter_test/flutter_test.dart';
import 'package:realestate_app/features/property_wizard/data/models/contact.dart';
import 'package:realestate_app/features/property_wizard/data/models/listing_valuation.dart';
import 'package:realestate_app/features/property_wizard/data/models/property_state.dart';
import 'package:realestate_app/features/property_wizard/data/models/room.dart';
import 'package:realestate_app/features/property_wizard/providers/wizard_navigation_provider.dart';

void main() {
  group('WizardNavigationData', () {
    test(
      'fromState shows canGoNext false when street is empty on address step',
      () {
        final state = PropertyState(currentStep: 2, street: '', city: '');

        final nav = WizardNavigationData.fromState(state);

        expect(nav.canGoNext, false);
      },
    );

    test(
      'fromState shows canGoNext true when street and city are filled on address step',
      () {
        final state = PropertyState(
          currentStep: 2,
          street: 'Main St',
          city: 'Cape Town',
        );

        final nav = WizardNavigationData.fromState(state);

        expect(nav.canGoNext, true);
      },
    );

    test(
      'fromState shows canGoNext false when no rooms on property features step',
      () {
        final state = PropertyState(currentStep: 4, rooms: []);

        final nav = WizardNavigationData.fromState(state);

        expect(nav.canGoNext, false);
      },
    );

    test(
      'fromState shows canGoNext true when rooms exist on property features step',
      () {
        final state = PropertyState(
          currentStep: 4,
          rooms: [Room(id: '1', name: 'Bedroom', roomTypeId: 1)],
        );

        final nav = WizardNavigationData.fromState(state);

        expect(nav.canGoNext, true);
      },
    );

    test(
      'fromState shows canGoNext false when no owner price on valuation step',
      () {
        final state = PropertyState(
          currentStep: 5,
          listingValuation: const ListingValuation(ownersNetPrice: ''),
        );

        final nav = WizardNavigationData.fromState(state);

        expect(nav.canGoNext, false);
      },
    );

    test(
      'fromState shows canGoNext true when owner price is set on valuation step',
      () {
        final state = PropertyState(
          currentStep: 5,
          listingValuation: const ListingValuation(ownersNetPrice: '2500000'),
        );

        final nav = WizardNavigationData.fromState(state);

        expect(nav.canGoNext, true);
      },
    );

    test('fromState shows canGoNext false when contact name is empty', () {
      final state = PropertyState(
        currentStep: 6,
        primaryContact: const Contact(fullName: ''),
      );

      final nav = WizardNavigationData.fromState(state);

      expect(nav.canGoNext, false);
    });

    test('fromState shows canGoNext true when contact name is filled', () {
      final state = PropertyState(
        currentStep: 6,
        primaryContact: const Contact(fullName: 'John Doe'),
      );

      final nav = WizardNavigationData.fromState(state);

      expect(nav.canGoNext, true);
    });

    test('fromState always allows review step', () {
      final state = PropertyState(currentStep: 7);

      final nav = WizardNavigationData.fromState(state);

      expect(nav.canGoNext, true);
    });
  });
}

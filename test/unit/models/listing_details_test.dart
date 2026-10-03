import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/property_overview/data/models/listing_details.dart';
import 'package:realworth/features/property_overview/data/models/listing_valuation.dart';
import 'package:realworth/features/property_overview/data/models/property_state.dart';
import 'package:realworth/features/property_overview/data/models/room.dart';
import 'package:realworth/features/property_overview/data/models/unit_details.dart';
import 'package:realworth/features/property_report/data/models/area_details.dart';
import 'package:realworth/features/property_report/data/models/marketing_area.dart';
import 'package:realworth/features/property_report/data/models/property_report.dart';
import 'package:realworth/features/property_report/data/pack_record.dart';
import 'package:realworth/features/property_report/presentation/widgets/report_pack_sheet.dart';
import 'package:realworth/features/property_report/providers/city_records_autofill.dart';
import 'package:realworth/features/property_report/report/pack_listing.dart';
import 'package:realworth/features/report_settings/data/models/report_settings.dart';

// Live report for 17 Pine Road, Claremont (erf 53927); range R 8.21–12.94 m.
Map<String, dynamic> _json() =>
    jsonDecode(
          File('test/fixtures/property_report_53927.json').readAsStringSync(),
        )
        as Map<String, dynamic>;

void main() {
  group('UnitDetails', () {
    test('describes a flatlet in words, rent in Rand', () {
      const unit = UnitDetails(
        bedrooms: 0,
        bathrooms: 1,
        kitchens: 1,
        kitchenette: true,
        ownEntrance: true,
        letOut: true,
        monthlyRent: '6500',
      );
      expect(
        unit.summary(money: rand),
        'Bachelor flat, 1 bathroom, kitchenette, own entrance, '
        'let at R 6 500 a month',
      );
      expect(unit.shortSummary, 'Bachelor flat · 1 bathroom · let out');
    });

    test('round-trips through JSON; rent only when let out', () {
      const unit = UnitDetails(bedrooms: 2, lounges: 1, monthlyRent: '5000');
      final json = unit.toJson();
      expect(json.containsKey('monthlyRent'), isFalse);
      final back = UnitDetails.fromJson(json);
      expect(back.bedrooms, 2);
      expect(back.lounges, 1);
      expect(back.letOut, isFalse);
    });

    test('knows flatlet room names', () {
      expect(UnitDetails.isFlatletName('Flatlet / Garden Cottage'), isTrue);
      expect(UnitDetails.isFlatletName('Granny flat'), isTrue);
      expect(UnitDetails.isFlatletName('Lounge'), isFalse);
    });

    test('a flatlet with its layout is described in the pack', () {
      final s = PropertyState(
        rooms: [
          Room(
            id: '1',
            name: 'Flatlet / Garden Cottage',
            roomTypeId: 7,
            unit: const UnitDetails(bedrooms: 1, bathrooms: 1),
          ),
        ],
      );
      expect(
        packPortfolio(s),
        contains('Flatlet: 1 bedroom, 1 bathroom, 1 kitchen'),
      );
      expect(
        packInspection(s).rooms.single.unitSummary,
        startsWith('1 bedroom'),
      );
    });
  });

  group('Price & Commission and the pack', () {
    const defaults = CalculatorDefaults();

    test('empty figures fall back to Report settings', () {
      final c = calculatorForListing(
        defaults,
        const ListingValuation(commissionPercent: '4.5', bondTermYears: '30'),
      );
      expect(c.commissionEarlyPercent, 4.5);
      expect(c.bondTermYears, 30);
      expect(c.commissionLatePercent, defaults.commissionLatePercent);
      expect(c.interestRatePercent, defaults.interestRatePercent);
    });

    test("the pack starts from the listing's own range and price", () {
      final report = PropertyReport.fromJson(_json());
      final o = initialPackOptions(
        report: report,
        preparedFor: 'Piet',
        greeting: 'Piet',
        valuation: const ListingValuation(
          valueLow: '9000000',
          valueHigh: '9500000',
          listingPrice: '9950000',
          adjustmentReason: 'the flatlet',
        ),
        calculator: defaults,
      );
      expect(o.low, 9000000);
      expect(o.high, 9500000);
      expect(o.listingPrice, 9950000);
      expect(o.adjustmentReason, 'the flatlet');
    });

    test("without the agent's figures it starts from the report", () {
      final o = initialPackOptions(
        report: PropertyReport.fromJson(_json()),
        preparedFor: '',
        greeting: '',
        valuation: const ListingValuation(),
        calculator: defaults,
      );
      expect(o.low, 8210000);
      expect(o.high, 12940000);
    });

    test('what the pack used is written back to the listing', () {
      final v = valuationWithPack(
        const ListingValuation(ownersNetPrice: '9000000'),
        const PackOptions(
          preparedFor: '',
          greeting: '',
          low: 9000000,
          high: 9600000,
          listingPrice: 9990000,
          calculator: CalculatorDefaults(commissionEarlyPercent: 5.5),
        ),
      );
      expect(v.valueLow, '9000000');
      expect(v.valueHigh, '9600000');
      expect(v.agentValuation, '9300000');
      expect(v.listingPrice, '9990000');
      expect(v.commissionPercent, '5.5');
      expect(v.ownersNetPrice, '9000000');
    });
  });

  group('Purchase from the last registered sale', () {
    Map<String, dynamic> withSale() => {
      ..._json(),
      'lastSale': {'saleDate': '2014-03-20', 'priceZar': 1900000},
    };

    test('fills an empty purchase', () {
      final plan = planAutofill(
        PropertyState(),
        PropertyReport.fromJson(withSale()),
      );
      expect(plan.lastPurchase?.priceZar, 1900000);
      expect(plan.touchesValuation, isTrue);
      expect(plan.filled.join(' | '), contains('last sale (2014'));
    });

    test('never overwrites what the owners said', () {
      final plan = planAutofill(
        PropertyState(
          listingValuation: const ListingValuation(lastPurchasePrice: '1'),
        ),
        PropertyReport.fromJson(withSale()),
      );
      expect(plan.lastPurchase, isNull);
    });
  });

  group('Report pack', () {
    test('counts the rent of let flatlets only', () {
      final s = PropertyState(
        rooms: [
          Room(
            id: '1',
            name: 'Flatlet',
            unit: const UnitDetails(letOut: true, monthlyRent: '6500'),
          ),
          Room(
            id: '2',
            name: 'Cottage',
            unit: const UnitDetails(monthlyRent: '4000'),
          ),
          Room(id: '3', name: 'Lounge'),
        ],
      );
      expect(packFlatletRents(s), [6500]);
    });

    test('is out of date when a figure changes, not when a photo uploads', () {
      final made = PropertyState(
        street: 'Bosman Street',
        exteriorPhotos: const ['/data/user/0/photo-1.jpg'],
        listingValuation: const ListingValuation(listingPrice: '2950000'),
      );
      final uploaded = made.copyWith(
        exteriorPhotos: const ['https://cdn.example/photo-1.jpg'],
      );
      expect(packFingerprint(uploaded), packFingerprint(made));
      final repriced = made.copyWith(
        listingValuation: made.listingValuation.copyWith(
          listingPrice: '2850000',
        ),
      );
      expect(packFingerprint(repriced), isNot(packFingerprint(made)));
    });
  });

  group('Marketing area', () {
    ForSaleListing home(String suburb, double? m) => ForSaleListing(
      listingNumber: '$suburb$m',
      url: '',
      title: '',
      suburb: suburb,
      distanceM: m,
    );
    ForSale forSale(List<ForSaleListing> listings) => ForSale(
      source: 'Property24',
      attribution: '',
      suburbs: const [ForSaleSuburb(1, "Lynn's View", 'Somerset West', '')],
      listings: listings,
    );

    test("is the Property24 suburb of the nearest homes", () {
      expect(
        suggestMarketingArea(
          forSale([
            home('Steynsrust', 120),
            home('Steynsrust', 300),
            home("Lynn's View", 250),
            home('Strand North', 1900),
          ]),
        ),
        'Steynsrust',
      );
    });

    test(
      "falls back to Property24's matched suburb; homes too far count not",
      () {
        expect(
          suggestMarketingArea(forSale([home('Far Away', 5000)])),
          "Lynn's View",
        );
        expect(suggestMarketingArea(null), isNull);
      },
    );
  });

  group('Listing details (myEdge form)', () {
    test('round-trips, keeping only what is set', () {
      final d = ListingDetails(
        ownershipType: 'Full Title',
        subtype: 'Free Standing',
        roof: const ['Tile'],
        overallCondition: 'Good',
        mandateType: 'Sole Mandate',
        mandateExpiry: DateTime(2027, 1, 3),
        renovations: const [
          Renovation(year: 2019, amount: '360000', description: 'Kitchen'),
        ],
      );
      final json = d.toJson();
      expect(json.containsKey('walls'), isFalse);
      expect(json['mandateExpiry'], '2027-01-03');
      final back = ListingDetails.parse(d.encode());
      expect(back.roof, ['Tile']);
      expect(back.mandateExpiry, DateTime(2027, 1, 3));
      expect(back.renovations.single.year, 2019);
      expect(back.hasMandateInfo, isTrue);
      expect(ListingDetails.parse('not json').hasMandateInfo, isFalse);
    });

    test('the pack names the kind of home and its renovations', () {
      final lines = packPortfolio(
        PropertyState(
          details: const ListingDetails(
            subtype: 'Free Standing',
            ownershipType: 'Full Title',
            renovations: [
              Renovation(year: 2019, amount: '360000', description: 'kitchen'),
            ],
          ),
        ),
      );
      expect(lines, contains('Free Standing, Full Title'));
      expect(lines, contains('Renovated in 2019 (R 360 000): kitchen'));
    });
  });
}

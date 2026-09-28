import 'dart:math' as math;

// "Costs to seller and buyer" for the report pack.
//
// The tables below change once a year. Current as at 27 Sep 2026:
//   * Transfer duty: SARS, 1 April 2026 (unchanged from 1 April 2025).
//     https://www.sars.gov.za/tax-rates/transfer-duty/
//   * Conveyancer and bond attorney fees: LSSA "Guideline of Fees,
//     Conveyancing", effective 1 July 2026, excluding VAT (one schedule for
//     transfers and bonds).
//   * Deeds Office fees: GN 7180 of 27 Feb 2026, effective 1 April 2026, no
//     VAT. https://www.deeds.gov.za/fees.php
// Attorneys' disbursements (postage, electronic generation, searches, FICA)
// are set by each firm; [attorneyExtras] is a typical figure, incl. VAT.

const double vatRate = 0.15;

/// A typical attorney's disbursements on a transfer or a bond, incl. VAT.
const double attorneyExtras = 3208.75;

/// SARS transfer duty: [upTo, base, rate, over].
const _transferDuty = <(double, double, double, double)>[
  (1210000, 0, 0.00, 0),
  (1663800, 0, 0.03, 1210000),
  (2329300, 13614, 0.06, 1663800),
  (2994800, 53544, 0.08, 2329300),
  (13310000, 106784, 0.11, 2994800),
  (double.infinity, 1241456, 0.13, 13310000),
];

double transferDuty(double price) {
  for (final (upTo, base, rate, over) in _transferDuty) {
    if (price <= upTo) return base + rate * (price - over);
  }
  return 0;
}

/// LSSA 2026 guideline fee, excluding VAT, for a transfer (by price) or a bond
/// (by amount). "Or part thereof": steps round up.
double conveyancingFee(double value) {
  int steps(double over, double size) => ((value - over) / size).ceil();
  if (value <= 100000) return 6875;
  if (value <= 500000) return 6875 + 1100.0 * steps(100000, 50000);
  if (value <= 1000000) return 15675 + 2120.0 * steps(500000, 100000);
  if (value <= 5000000) return 26275 + 2120.0 * steps(1000000, 200000);
  return 68675 + 5340.0 * steps(5000000, 1000000);
}

/// Deeds Office fee for registering a transfer, by purchase price.
double deedsTransferFee(double price) => _band(price, const [
  (100000, 50),
  (200000, 114),
  (300000, 727),
  (600000, 956),
  (800000, 1346),
  (1000000, 1546),
  (2000000, 1738),
  (4000000, 2408),
  (6000000, 2922),
  (8000000, 3480),
  (10000000, 4068),
  (15000000, 4844),
  (20000000, 5818),
  (double.infinity, 7751),
]);

/// Deeds Office fee for registering a bond, by capital amount.
double deedsBondFee(double amount) => _band(amount, const [
  (150000, 561),
  (300000, 727),
  (600000, 956),
  (800000, 1346),
  (1000000, 1546),
  (2000000, 1738),
  (4000000, 2408),
  (6000000, 2922),
  (8000000, 3480),
  (10000000, 4068),
  (15000000, 4844),
  (20000000, 5818),
  (30000000, 6781),
  (double.infinity, 9690),
]);

double _band(double value, List<(double, double)> table) =>
    table.firstWhere((b) => value <= b.$1).$2;

/// Monthly repayment on a home loan (standard amortisation).
double monthlyRepayment(double principal, double ratePercent, int years) {
  if (principal <= 0) return 0;
  final i = ratePercent / 100 / 12;
  final n = years * 12;
  if (i == 0) return principal / n;
  return principal * i / (1 - math.pow(1 + i, -n));
}

class TransferCosts {
  final double duty;
  final double attorneyFee; // incl. VAT
  final double deedsFee;
  final double extras;
  const TransferCosts(this.duty, this.attorneyFee, this.deedsFee, this.extras);
  double get total => duty + attorneyFee + deedsFee + extras;

  factory TransferCosts.of(double price) => TransferCosts(
    transferDuty(price),
    conveyancingFee(price) * (1 + vatRate),
    deedsTransferFee(price),
    attorneyExtras,
  );
}

class BondCosts {
  final double amount;
  final double attorneyFee; // incl. VAT
  final double deedsFee;
  final double extras;
  const BondCosts(this.amount, this.attorneyFee, this.deedsFee, this.extras);
  double get total => attorneyFee + deedsFee + extras;

  factory BondCosts.of(double amount) => amount <= 0
      ? const BondCosts(0, 0, 0, 0)
      : BondCosts(
          amount,
          conveyancingFee(amount) * (1 + vatRate),
          deedsBondFee(amount),
          attorneyExtras,
        );
}

/// What the seller keeps at one price: commission if it sells quickly, and if
/// it takes longer.
class SellerProceeds {
  final double price;
  final double commissionEarly;
  final double commissionLate;
  const SellerProceeds(this.price, this.commissionEarly, this.commissionLate);
  double get netEarly => price - commissionEarly;
  double get netLate => price - commissionLate;
}

/// Everything on the "Costs to seller and buyer" page, from the report's
/// figures and the agent's calculator settings (both editable per report).
class CostsSummary {
  final double valuationPrice;
  final double? listingPrice;
  final double commissionEarlyPercent;
  final double commissionLatePercent;
  final int earlyMonths;
  final bool commissionIncludesVat;
  final double interestRatePercent;
  final int bondTermYears;
  final double depositPercent;

  const CostsSummary({
    required this.valuationPrice,
    this.listingPrice,
    required this.commissionEarlyPercent,
    required this.commissionLatePercent,
    required this.earlyMonths,
    required this.commissionIncludesVat,
    required this.interestRatePercent,
    required this.bondTermYears,
    required this.depositPercent,
  });

  SellerProceeds proceedsAt(double price) {
    final vat = commissionIncludesVat ? 1 + vatRate : 1.0;
    return SellerProceeds(
      price,
      price * commissionEarlyPercent / 100 * vat,
      price * commissionLatePercent / 100 * vat,
    );
  }

  /// The seller at the valuation, and at the listing price when it differs.
  List<SellerProceeds> get seller => [
    proceedsAt(valuationPrice),
    if (listingPrice != null && listingPrice != valuationPrice)
      proceedsAt(listingPrice!),
  ];

  TransferCosts get transfer => TransferCosts.of(valuationPrice);

  double get bondAmount => valuationPrice * (1 - depositPercent / 100);

  BondCosts get bond => BondCosts.of(bondAmount);

  /// Price + transfer + bond costs: what the home costs the buyer.
  double get buyerTotal => valuationPrice + transfer.total + bond.total;

  double get monthlyRepaymentAmount =>
      monthlyRepayment(bondAmount, interestRatePercent, bondTermYears);

  double get totalRepayable => monthlyRepaymentAmount * bondTermYears * 12;
}

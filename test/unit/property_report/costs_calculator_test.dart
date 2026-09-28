import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/property_report/report/costs_calculator.dart';

void main() {
  test('transfer duty follows the SARS 2026 table', () {
    expect(transferDuty(1200000), 0);
    expect(transferDuty(1500000), closeTo(8700, 0.01));
    expect(transferDuty(5300000), closeTo(360356, 0.01));
  });

  test('the conveyancing fee steps up per band, rounding up', () {
    expect(conveyancingFee(100000), 6875);
    expect(conveyancingFee(100001), 6875 + 1100);
    expect(conveyancingFee(5300000), 74015);
  });

  // An agent's report for a R5 300 000 sale (Sept 2026): "R451 604 – Transfer
  // cost", "R91 248 – Bond cost", "R5 842 852 – what your home will cost the
  // future buyer".
  test("reproduces an agent's costs page for R5 300 000", () {
    final transfer = TransferCosts.of(5300000);
    expect(transfer.duty, closeTo(360356, 0.01));
    expect(transfer.attorneyFee, closeTo(85117.25, 0.01));
    expect(transfer.deedsFee, 2922);
    expect(transfer.total.round(), 451604);

    expect(BondCosts.of(5300000).total.round(), 91248);

    const summary = CostsSummary(
      valuationPrice: 5300000,
      listingPrice: 5600000,
      commissionEarlyPercent: 5,
      commissionLatePercent: 6,
      earlyMonths: 2,
      commissionIncludesVat: false,
      interestRatePercent: 10.5,
      bondTermYears: 20,
      depositPercent: 0,
    );
    expect(summary.buyerTotal.round(), 5842852);
    expect(summary.seller.first.netEarly, 5035000);
    expect(summary.seller.first.netLate, 4982000);
    expect(summary.seller.last.netEarly, 5320000);
    expect(summary.seller.last.netLate, 5264000);
    expect(summary.monthlyRepaymentAmount, closeTo(52914.13, 0.01));
  });

  test('a deposit shrinks the bond', () {
    const summary = CostsSummary(
      valuationPrice: 2000000,
      commissionEarlyPercent: 5,
      commissionLatePercent: 6,
      earlyMonths: 2,
      commissionIncludesVat: true,
      interestRatePercent: 10.75,
      bondTermYears: 20,
      depositPercent: 10,
    );
    expect(summary.bondAmount, 1800000);
    expect(summary.seller.single.commissionEarly, closeTo(115000, 0.01));
  });
}

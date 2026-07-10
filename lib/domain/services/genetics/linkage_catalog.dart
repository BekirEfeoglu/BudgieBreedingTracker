import 'package:budgie_breeding_tracker/core/constants/genetics_constants.dart';

/// How a Z-chromosome linkage distance was established.
///
/// Used so the UI never presents a derived or estimated distance as if it were
/// a directly measured value.
enum LinkageEvidence {
  /// Directly measured in test-mating / crossover studies.
  measured,

  /// Inferred from the sum/difference of measured flanking distances.
  derived,

  /// Best-guess from gene-map order; no direct study.
  estimated,
}

/// A single Z-chromosome linkage relationship between two loci.
///
/// [locusA] and [locusB] are canonical locus tokens (`opaline`, `cinnamon`,
/// `ino`, `slate`), always stored alphabetically so `(a,b)` and `(b,a)` map to
/// the same record.
class LinkagePairInfo {
  const LinkagePairInfo({
    required this.locusA,
    required this.locusB,
    required this.recombinationRate,
    required this.evidence,
    required this.sourceNote,
  });

  /// Alphabetically-first canonical locus token.
  final String locusA;

  /// Alphabetically-second canonical locus token.
  final String locusB;

  /// Recombination fraction the engine uses (0..0.5). This is the SAME value
  /// [GeneticsConstants] feeds `_calculateGenericLinkedPair`, so display and
  /// calculation can never drift apart.
  final double recombinationRate;

  /// Provenance of [recombinationRate].
  final LinkageEvidence evidence;

  /// Short, non-quoted source note for the distance.
  final String sourceNote;

  /// Display distance in centiMorgans (`recombinationRate * 100`), rounded to a
  /// single decimal so float noise never leaks into the UI (`0.405 → 40.5`).
  double get displayCentiMorgans => (recombinationRate * 1000).round() / 10;

  /// [displayCentiMorgans] as a compact label: integers drop the decimal
  /// (`32.0 → "32"`), non-integers keep it (`40.5 → "40.5"`).
  String get displayCentiMorgansLabel {
    final cm = displayCentiMorgans;
    return cm == cm.roundToDouble()
        ? cm.toStringAsFixed(0)
        : cm.toString();
  }
}

/// Single source of truth for Z-chromosome linkage distances.
///
/// The engine ([mendelian_calculator]) AND every UI surface
/// (`z_linked_badge`, `mutation_detail_sheet`) read distances from here, so a
/// linkage value is declared exactly once. Gene order on Z:
/// `Opaline — Cinnamon — Ino — Slate`.
///
/// The four ino-locus alleles (`ino`, `pallid`, `pearly`, `texas_clearbody`)
/// share the same physical position, so they all normalise to the `ino` token
/// and inherit ino's distances — matching the v3 linkage generalisation.
abstract final class LinkageCatalog {
  /// Ino-locus alleles that occupy the same Z position as literal `ino`.
  static const Set<String> _inoLocusAlleleIds = {
    GeneticsConstants.mutIno,
    GeneticsConstants.mutPallid,
    GeneticsConstants.mutPearly,
    GeneticsConstants.mutTexasClearbody,
  };

  /// The three standalone linkage loci (each is its own canonical token).
  static const Set<String> _standaloneLoci = {
    GeneticsConstants.mutOpaline,
    GeneticsConstants.mutCinnamon,
    GeneticsConstants.mutSlate,
  };

  /// Canonical token used for any ino-locus allele in linkage lookups.
  static const String inoLocusToken = GeneticsConstants.mutIno;

  /// The six canonical linkage pairs, keyed by `'<a>|<b>'` (tokens sorted).
  static final Map<String, LinkagePairInfo> _byPairKey = {
    for (final info in _entries) _key(info.locusA, info.locusB): info,
  };

  static final List<LinkagePairInfo> _entries = [
    const LinkagePairInfo(
      locusA: GeneticsConstants.mutCinnamon,
      locusB: GeneticsConstants.mutIno,
      recombinationRate: GeneticsConstants.cinnamonInoRecombination,
      evidence: LinkageEvidence.measured,
      sourceNote: 'Warner & Daniels (1/36 ≈ 2.8%); MUTAVI research data',
    ),
    const LinkagePairInfo(
      locusA: GeneticsConstants.mutIno,
      locusB: GeneticsConstants.mutSlate,
      recombinationRate: GeneticsConstants.inoSlateRecombination,
      evidence: LinkageEvidence.estimated,
      sourceNote:
          'Estimated from MUTAVI Z gene map: Cin–Slate (5) − Cin–Ino (3) ≈ 2 cM',
    ),
    const LinkagePairInfo(
      locusA: GeneticsConstants.mutCinnamon,
      locusB: GeneticsConstants.mutSlate,
      recombinationRate: GeneticsConstants.cinnamonSlateRecombination,
      evidence: LinkageEvidence.measured,
      sourceNote: 'MUTAVI research data, test-mating studies',
    ),
    const LinkagePairInfo(
      locusA: GeneticsConstants.mutIno,
      locusB: GeneticsConstants.mutOpaline,
      recombinationRate: GeneticsConstants.opalineInoRecombination,
      evidence: LinkageEvidence.derived,
      sourceNote:
          'Derived from flanking distances: Op–Cin (32) − Cin–Ino (3) ≈ 29–30 cM; '
          'not directly measured',
    ),
    const LinkagePairInfo(
      locusA: GeneticsConstants.mutCinnamon,
      locusB: GeneticsConstants.mutOpaline,
      recombinationRate: GeneticsConstants.opalineCinnamonRecombination,
      evidence: LinkageEvidence.measured,
      sourceNote:
          'MUTAVI, Crossing-over in the Sex-chromosome of the Male Budgerigar',
    ),
    const LinkagePairInfo(
      locusA: GeneticsConstants.mutOpaline,
      locusB: GeneticsConstants.mutSlate,
      recombinationRate: GeneticsConstants.opalineSlateRecombination,
      evidence: LinkageEvidence.measured,
      sourceNote:
          'MUTAVI, Crossing-over in the Sex-chromosome of the Male Budgerigar',
    ),
  ];

  static String _key(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}|${sorted[1]}';
  }

  /// Canonical linkage token for a mutation id, or `null` if it does not
  /// participate in Z linkage. All ino-locus alleles collapse to [inoLocusToken].
  static String? normalizeToken(String mutationId) {
    if (_inoLocusAlleleIds.contains(mutationId)) return inoLocusToken;
    if (_standaloneLoci.contains(mutationId)) return mutationId;
    return null;
  }

  /// Symmetric lookup for the linkage between two mutation ids. Returns `null`
  /// when either id is not a linkage participant, or both map to the same locus
  /// (e.g. `pearly` and `texas_clearbody` share the ino position).
  static LinkagePairInfo? lookup(String mutationIdA, String mutationIdB) {
    final a = normalizeToken(mutationIdA);
    final b = normalizeToken(mutationIdB);
    if (a == null || b == null || a == b) return null;
    return _byPairKey[_key(a, b)];
  }

  /// Recombination fraction between two mutation ids, or `null` if unlinked.
  static double? recombinationRateFor(String mutationIdA, String mutationIdB) =>
      lookup(mutationIdA, mutationIdB)?.recombinationRate;

  /// All linkage relationships for [mutationId], sorted tightest-first (lowest
  /// recombination). Each entry pairs the partner locus token with its info.
  /// Empty when [mutationId] is not a linkage participant.
  static List<({String partnerLocus, LinkagePairInfo info})> linkagesFor(
    String mutationId,
  ) {
    final token = normalizeToken(mutationId);
    if (token == null) return const [];
    final out = <({String partnerLocus, LinkagePairInfo info})>[];
    for (final info in _entries) {
      final String partner;
      if (info.locusA == token) {
        partner = info.locusB;
      } else if (info.locusB == token) {
        partner = info.locusA;
      } else {
        continue;
      }
      out.add((partnerLocus: partner, info: info));
    }
    out.sort(
      (x, y) => x.info.recombinationRate.compareTo(y.info.recombinationRate),
    );
    return out;
  }

  /// All six canonical linkage pairs (unmodifiable view, for tests/tooling).
  static List<LinkagePairInfo> get allPairs => List.unmodifiable(_entries);
}

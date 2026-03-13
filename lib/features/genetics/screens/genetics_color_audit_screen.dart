import 'package:flutter/material.dart';

import 'package:budgie_breeding_tracker/features/genetics/widgets/bird_color_simulation.dart';

class GeneticsColorAuditScreen extends StatelessWidget {
  const GeneticsColorAuditScreen({super.key});

  static const _primarySamples = <_AuditSample>[
    _AuditSample(
      title: 'Light Green',
      note: 'WBO 375',
      phenotype: 'Light Green',
      visualMutations: [],
    ),
    _AuditSample(
      title: 'Grey-Green',
      note: 'Grey cheek',
      phenotype: 'Grey-Green',
      visualMutations: ['grey'],
    ),
    _AuditSample(
      title: 'Skyblue',
      note: 'WBO 310',
      phenotype: 'Skyblue',
      visualMutations: ['blue'],
    ),
    _AuditSample(
      title: 'Cobalt',
      note: 'WBO 2915',
      phenotype: 'Cobalt',
      visualMutations: ['blue', 'dark_factor'],
    ),
    _AuditSample(
      title: 'Grey',
      note: 'Grey cheek',
      phenotype: 'Grey',
      visualMutations: ['blue', 'grey'],
    ),
    _AuditSample(
      title: 'Anthracite DF',
      note: 'Dark cheek/body',
      phenotype: 'Double Factor Anthracite',
      visualMutations: ['anthracite'],
    ),
    _AuditSample(
      title: 'Cinnamon Skyblue',
      note: '50% body depth',
      phenotype: 'Cinnamon Skyblue',
      visualMutations: ['blue', 'cinnamon'],
    ),
    _AuditSample(
      title: 'Greywing Skyblue',
      note: '50% + pale cheek',
      phenotype: 'Skyblue Greywing',
      visualMutations: ['blue', 'greywing'],
    ),
    _AuditSample(
      title: 'Dom. Clearbody',
      note: 'Smoky grey cheek',
      phenotype: 'Dominant Clearbody Skyblue',
      visualMutations: ['blue', 'dominant_clearbody'],
    ),
    _AuditSample(
      title: 'Texas Clearbody',
      note: 'Pale body suffusion',
      phenotype: 'Skyblue Texas Clearbody',
      visualMutations: ['blue', 'texas_clearbody'],
    ),
    _AuditSample(
      title: 'Lutino',
      note: 'White cheek',
      phenotype: 'Lutino',
      visualMutations: ['ino'],
    ),
    _AuditSample(
      title: 'Albino',
      note: 'White cheek',
      phenotype: 'Albino',
      visualMutations: ['ino', 'blue'],
    ),
  ];

  static const _advancedSamples = <_AuditSample>[
    _AuditSample(
      title: 'Visual Violet',
      note: 'Series violet',
      phenotype: 'Visual Violet Skyblue',
      visualMutations: ['blue', 'violet'],
    ),
    _AuditSample(
      title: 'Mauve',
      note: 'Dark factor blue',
      phenotype: 'Mauve',
      visualMutations: ['blue', 'dark_factor'],
    ),
    _AuditSample(
      title: 'Slate',
      note: 'Deep violet cheek',
      phenotype: 'Slate',
      visualMutations: ['slate'],
    ),
    _AuditSample(
      title: 'Green Slate',
      note: 'Muted grey-green',
      phenotype: 'Light Green Slate',
      visualMutations: ['slate'],
    ),
    _AuditSample(
      title: 'SF Anthracite',
      note: 'Deeper green, not charcoal',
      phenotype: 'Light Green Single Factor Anthracite',
      visualMutations: ['anthracite'],
    ),
    _AuditSample(
      title: 'Blackface',
      note: 'Black mask',
      phenotype: 'Blackface Light Green',
      visualMutations: ['blackface'],
    ),
    _AuditSample(
      title: 'DF Spangle',
      note: 'Silver-white cheek',
      phenotype: 'Double Factor Spangle',
      visualMutations: ['blue', 'spangle'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(title: const Text('Genetics Color Audit')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          children: const [
            GeneticsPrimaryColorAuditBoard(),
            SizedBox(height: 16),
            GeneticsAdvancedColorAuditBoard(),
          ],
        ),
      ),
    );
  }
}

class GeneticsPrimaryColorAuditBoard extends StatelessWidget {
  const GeneticsPrimaryColorAuditBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return const GeneticsColorAuditBoard(
      title: 'Critical phenotype audit board',
      subtitle: 'WBO base tones + high-risk mutation visuals',
      samples: GeneticsColorAuditScreen._primarySamples,
      minTileWidth: 88,
      birdSize: 52,
    );
  }
}

class GeneticsAdvancedColorAuditBoard extends StatelessWidget {
  const GeneticsAdvancedColorAuditBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return const GeneticsColorAuditBoard(
      title: 'Advanced mutation audit board',
      subtitle:
          'Violet, mauve, slate, anthracite, blackface, and DF spangle checks',
      samples: GeneticsColorAuditScreen._advancedSamples,
      minTileWidth: 106,
      birdSize: 62,
    );
  }
}

class GeneticsColorAuditBoard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_AuditSample> samples;
  final double minTileWidth;
  final double birdSize;

  const GeneticsColorAuditBoard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.samples,
    required this.minTileWidth,
    required this.birdSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE3F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = (constraints.maxWidth / minTileWidth)
                    .floor()
                    .clamp(2, 5);

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.70,
                  ),
                  itemCount: samples.length,
                  itemBuilder: (context, index) {
                    final sample = samples[index];
                    return _AuditSampleCard(sample: sample, birdSize: birdSize);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditSampleCard extends StatelessWidget {
  final _AuditSample sample;
  final double birdSize;

  const _AuditSampleCard({required this.sample, required this.birdSize});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE3F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BirdColorSimulation(
              visualMutations: sample.visualMutations,
              phenotype: sample.phenotype,
              size: birdSize,
            ),
            const SizedBox(height: 8),
            Text(
              sample.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              sample.note,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 9,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditSample {
  final String title;
  final String note;
  final String phenotype;
  final List<String> visualMutations;

  const _AuditSample({
    required this.title,
    required this.note,
    required this.phenotype,
    required this.visualMutations,
  });
}

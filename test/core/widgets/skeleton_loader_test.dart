import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';

import 'package:budgie_breeding_tracker/core/widgets/skeleton_loader.dart';

void main() {
  testWidgets('renders shimmer skeleton with configured size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SkeletonLoader(width: 180, height: 24, borderRadius: 12),
        ),
      ),
    );

    expect(find.byType(Shimmer), findsOneWidget);
    final size = tester.getSize(find.byType(SkeletonLoader));
    expect(size.width, 180);
    expect(size.height, 24);
  });
}

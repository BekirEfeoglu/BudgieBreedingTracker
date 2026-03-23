import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/budgie_color_resolver.dart';

BudgieColorAppearance _resolve(String phenotype, {
  List<String> mutations = const [],
  List<String> carried = const [],
}) => BudgieColorResolver.resolve(
  visualMutations: mutations, phenotype: phenotype, carriedMutations: carried,
);

void main() {
  group('cheek patch interactions', () {
    test('greywing keeps base cheek per series', () {
      final blue = _resolve('Greywing Skyblue', mutations: ['greywing', 'blue']);
      expect(blue.cheekPatchColor, BudgiePhenotypePalette.cheekViolet);
      final green = _resolve('Greywing Light Green', mutations: ['greywing']);
      expect(green.cheekPatchColor, BudgiePhenotypePalette.cheekBlue);
    });

    test('greywing + grey overrides cheek to grey', () {
      final r = _resolve('Greywing Grey Skyblue',
          mutations: ['greywing', 'grey', 'blue']);
      expect(r.cheekPatchColor, BudgiePhenotypePalette.grey);
    });

    test('dilute cheek is only slightly diluted at 0.20 mix', () {
      final r = _resolve('Dilute Light Green', mutations: ['dilute']);
      final expected = Color.lerp(
        BudgiePhenotypePalette.cheekBlue, BudgiePhenotypePalette.maskYellow, 0.20,
      );
      expect(r.cheekPatchColor, expected);
    });

    test('fullbody greywing cheek per series', () {
      final blue = _resolve('Fullbody Greywing Skyblue',
          mutations: ['clearwing', 'greywing', 'blue']);
      expect(blue.cheekPatchColor, BudgiePhenotypePalette.cheekViolet);
      final green = _resolve('Fullbody Greywing Light Green',
          mutations: ['clearwing', 'greywing']);
      expect(green.cheekPatchColor, BudgiePhenotypePalette.cheekBlue);
    });

    test('anthracite cheek is anthracite-tinted', () {
      final r = _resolve('Anthracite Skyblue', mutations: ['anthracite', 'blue']);
      final expected = Color.lerp(
        BudgiePhenotypePalette.anthraciteSingle,
        BudgiePhenotypePalette.anthraciteSingle, 0.18,
      );
      expect(r.cheekPatchColor, expected);
    });

    test('df anthracite cheek equals body color', () {
      final r = _resolve('Double Factor Anthracite Skyblue',
          mutations: ['anthracite', 'blue']);
      expect(r.cheekPatchColor, r.bodyColor);
    });

    test('dominant clearbody cheek is smokeGrey', () {
      final r = _resolve('Dominant Clearbody Light Green',
          mutations: ['dominant_clearbody']);
      expect(r.cheekPatchColor, BudgiePhenotypePalette.cheekSmokeGrey);
    });

    test('blackface cheek is cheekViolet', () {
      final r = _resolve('Blackface Light Green', mutations: ['blackface']);
      expect(r.cheekPatchColor, BudgiePhenotypePalette.cheekViolet);
    });
  });

  group('eye color interactions', () {
    test('normal has black eye, white ring, ring visible', () {
      final r = _resolve('Light Green');
      expect(r.eyeColor, const Color(0xFF1A1A1A));
      expect(r.eyeRingColor, const Color(0xFFF0F0F0));
      expect(r.showEyeRing, isTrue);
    });

    test('lutino has red eye, pink ring, ring visible', () {
      final r = _resolve('Lutino', mutations: ['ino']);
      expect(r.eyeColor, const Color(0xFFCC2233));
      expect(r.eyeRingColor, const Color(0xFFF2C8CC));
      expect(r.showEyeRing, isTrue);
    });

    test('albino has same red eye as lutino', () {
      final r = _resolve('Albino', mutations: ['ino', 'blue']);
      expect(r.eyeColor, const Color(0xFFCC2233));
    });

    test('english fallow has bright red eye, no ring', () {
      final r = _resolve('English Fallow Light Green',
          mutations: ['fallow_english']);
      expect(r.eyeColor, const Color(0xFFCC2838));
      expect(r.showEyeRing, isFalse);
    });

    test('german fallow has ruby red eye, ring visible', () {
      final r = _resolve('German Fallow Light Green',
          mutations: ['fallow_german']);
      expect(r.eyeColor, const Color(0xFFA82030));
      expect(r.showEyeRing, isTrue);
    });

    test('recessive pied has dark plum eye, no ring', () {
      final r = _resolve('Recessive Pied Light Green',
          mutations: ['recessive_pied']);
      expect(r.eyeColor, const Color(0xFF1F0F18));
      expect(r.showEyeRing, isFalse);
    });

    test('dark-eyed clear has dark eye (recessive pied priority), no ring', () {
      final r = _resolve('Dark-Eyed Clear Light Green',
          mutations: ['recessive_pied', 'clearflight_pied']);
      expect(r.eyeColor, const Color(0xFF1F0F18));
      expect(r.showEyeRing, isFalse);
    });

    test('df spangle has default black eye, ring visible', () {
      final r = _resolve('Double Factor Spangle Skyblue',
          mutations: ['spangle']);
      expect(r.eyeColor, const Color(0xFF1A1A1A));
      expect(r.showEyeRing, isTrue);
    });

    test('creamino and lacewing have red eye (ino variants)', () {
      final creamino = _resolve('Creamino', mutations: ['ino', 'blue']);
      expect(creamino.eyeColor, const Color(0xFFCC2233));
      final lacewing = _resolve('Lacewing Light Green',
          mutations: ['ino', 'cinnamon']);
      expect(lacewing.eyeColor, const Color(0xFFCC2233));
    });
  });

  group('tail color interactions', () {
    test('normal series tail colors', () {
      final green = _resolve('Light Green');
      expect(green.tailColor, const Color(0xFF2B4F6F));
      final blue = _resolve('Skyblue', mutations: ['blue']);
      expect(blue.tailColor, const Color(0xFF2B3F6F));
    });

    test('cinnamon has brown tail', () {
      final r = _resolve('Cinnamon Light Green', mutations: ['cinnamon']);
      expect(r.tailColor, const Color(0xFF6B5040));
    });

    test('dilute and greywing have wingGrey tail', () {
      final dilute = _resolve('Dilute Light Green', mutations: ['dilute']);
      expect(dilute.tailColor, BudgiePhenotypePalette.wingGrey);
      final gw = _resolve('Greywing Light Green', mutations: ['greywing']);
      expect(gw.tailColor, BudgiePhenotypePalette.wingGrey);
    });

    test('opaline tail is mix of baseTail and body', () {
      final r = _resolve('Opaline Light Green', mutations: ['opaline']);
      final expected = Color.lerp(const Color(0xFF2B4F6F), r.bodyColor, 0.30);
      expect(r.tailColor, expected);
    });

    test('lutino tail alpha 0.20, albino tail alpha 0.10', () {
      final lutino = _resolve('Lutino', mutations: ['ino']);
      expect(lutino.tailColor.a, closeTo(0.20, 0.02));
      final albino = _resolve('Albino', mutations: ['ino', 'blue']);
      expect(albino.tailColor.a, closeTo(0.10, 0.02));
    });
  });

  group('throat spot interactions', () {
    test('normal has 6 black spots, visible', () {
      final r = _resolve('Light Green');
      expect(r.showThroatSpots, isTrue);
      expect(r.throatSpotCount, 6);
      expect(r.throatSpotColor, const Color(0xFF1A1A1A));
    });

    test('opaline has 4 spots, visible', () {
      final r = _resolve('Opaline Light Green', mutations: ['opaline']);
      expect(r.throatSpotCount, 4);
      expect(r.showThroatSpots, isTrue);
    });

    test('opaline + cinnamon has 4 cinnamon spots', () {
      final r = _resolve('Opaline Cinnamon Light Green',
          mutations: ['opaline', 'cinnamon']);
      expect(r.throatSpotCount, 4);
      expect(r.throatSpotColor, BudgiePhenotypePalette.cinnamon);
    });

    test('cinnamon alone has 6 cinnamon spots', () {
      final r = _resolve('Cinnamon Light Green', mutations: ['cinnamon']);
      expect(r.throatSpotCount, 6);
      expect(r.throatSpotColor, BudgiePhenotypePalette.cinnamon);
    });

    test('dilute has 6 wingGrey spots', () {
      final r = _resolve('Dilute Light Green', mutations: ['dilute']);
      expect(r.throatSpotCount, 6);
      expect(r.throatSpotColor, BudgiePhenotypePalette.wingGrey);
    });

    test('ino, df spangle, dec all hide spots', () {
      for (final (phenotype, muts) in [
        ('Lutino', ['ino']),
        ('Double Factor Spangle Skyblue', ['spangle']),
        ('Dark-Eyed Clear Light Green', ['recessive_pied', 'clearflight_pied']),
      ]) {
        final r = _resolve(phenotype, mutations: muts);
        expect(r.showThroatSpots, isFalse, reason: phenotype);
        expect(r.throatSpotCount, 0, reason: phenotype);
      }
    });
  });

  group('back color interactions', () {
    test('normal has null backColor, effectiveBackColor = bodyColor', () {
      final r = _resolve('Light Green');
      expect(r.backColor, isNull);
      expect(r.effectiveBackColor, r.bodyColor);
    });

    test('opaline backColor equals bodyColor', () {
      final r = _resolve('Opaline Light Green', mutations: ['opaline']);
      expect(r.backColor, r.bodyColor);
    });

    test('opaline + cinnamon back is mix of body and cinnamon', () {
      final r = _resolve('Opaline Cinnamon Light Green',
          mutations: ['opaline', 'cinnamon']);
      final expected = Color.lerp(r.bodyColor, BudgiePhenotypePalette.cinnamon, 0.15);
      expect(r.backColor, expected);
    });

    test('texas clearbody back is lightened body', () {
      final r = _resolve('Texas Clearbody Light Green',
          mutations: ['texas_clearbody']);
      expect(r.backColor, isNotNull);
    });
  });

  group('beak color interactions', () {
    test('normal beak is golden', () {
      expect(_resolve('Light Green').beakColor, const Color(0xFFE8A830));
    });

    test('ino beak is lighter gold', () {
      final r = _resolve('Lutino', mutations: ['ino']);
      expect(r.beakColor, const Color(0xFFF0C060));
    });

    test('fallow beak is warm orange', () {
      final r = _resolve('English Fallow Light Green',
          mutations: ['fallow_english']);
      expect(r.beakColor, const Color(0xFFE89830));
    });
  });

  group('carrier accent', () {
    test('no carried mutations returns transparent', () {
      final r = _resolve('Light Green');
      expect(r.carrierAccentColor, Colors.transparent);
      expect(r.showCarrierAccent, isFalse);
    });

    test('carrying ino returns lutino color', () {
      final r = _resolve('Light Green', carried: ['ino']);
      expect(r.carrierAccentColor, BudgiePhenotypePalette.lutino);
      expect(r.showCarrierAccent, isTrue);
    });

    test('carrying blue returns skyBlue', () {
      final r = _resolve('Light Green', carried: ['blue']);
      expect(r.carrierAccentColor, BudgiePhenotypePalette.skyBlue);
    });

    test('carrying violet returns violet', () {
      final r = _resolve('Skyblue', mutations: ['blue'], carried: ['violet']);
      expect(r.carrierAccentColor, BudgiePhenotypePalette.violet);
    });

    test('carrying cinnamon returns cinnamon', () {
      final r = _resolve('Light Green', carried: ['cinnamon']);
      expect(r.carrierAccentColor, BudgiePhenotypePalette.cinnamon);
    });
  });
}

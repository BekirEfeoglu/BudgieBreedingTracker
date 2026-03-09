import { staticFile } from 'remotion';

export const loadFonts = () => {
  const fontFace = new FontFace(
    'Inter',
    `url('${staticFile('fonts/Inter-Variable.woff2')}') format('woff2')`,
    { weight: '100 900', style: 'normal' }
  );

  fontFace.load().then((loaded) => {
    document.fonts.add(loaded);
  });
};

export const fontFamily = 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';

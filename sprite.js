// Builds a cat frame from shared part grids (parts.js) plus that cat's marking overlays
// (markings.js), then paints it with the cat's palette (cats.js).
// Grids hold palette keys, not colours, so switching cats is just switching palettes.

const SPRITE_SIZE = 128;

// Back-to-front draw order. Head parts move up by frame.headUp pixels.
const LAYERS = [
  { part: 'chair', variant: () => 'default' },
  { part: 'tail', variant: (f) => f.tail },
  { part: 'torso', variant: (f) => f.torso },
  { part: 'haunches', variant: () => 'default' },
  { part: 'legs', variant: () => 'default' },
  { part: 'ears', variant: (f) => f.ears, head: true },
  { part: 'head', variant: () => 'default', head: true },
  { part: 'eyes', variant: (f) => f.eyes, head: true },
];

function pasteLayer(grid, layer, dy) {
  if (!layer) return;
  layer.rows.forEach((row, ry) => {
    const y = layer.y + ry + dy;
    if (y < 0 || y >= grid.length) return;
    for (let rx = 0; rx < row.length; rx++) {
      const ch = row[rx];
      if (ch !== '.') grid[y][layer.x + rx] = ch;
    }
  });
}

// Returns a size x size array of palette keys ('.' = transparent).
function composeFrame(frame, catId, size = SPRITE_SIZE) {
  const grid = Array.from({ length: size }, () => Array(size).fill('.'));
  for (const { part, variant, head } of LAYERS) {
    const v = variant(frame);
    const dy = head ? -(frame.headUp || 0) : 0;
    pasteLayer(grid, PARTS[part][v], dy);
    pasteLayer(grid, MARKINGS[catId]?.[part]?.[v], dy);
  }
  return grid;
}

// Paint a key grid onto a canvas context, one scale x scale block per pixel.
function paintGrid(ctx, grid, palette, scale = 1, ox = 0, oy = 0) {
  for (let y = 0; y < grid.length; y++) {
    for (let x = 0; x < grid[y].length; x++) {
      const color = palette[grid[y][x]];
      if (!color) continue;
      ctx.fillStyle = color;
      ctx.fillRect(ox + x * scale, oy + y * scale, scale, scale);
    }
  }
}

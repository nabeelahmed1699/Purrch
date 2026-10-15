// Purrch cats — one palette per cat. Every cat shares the same pixel parts (parts.js);
// switching palette is all it takes to switch cats. Markings live in markings.js.
//
// Palette keys:
//   o  outline / pupil / mouth
//   h  fur highlight
//   j  fur light
//   b  fur base
//   u  fur mid shadow
//   s  fur shadow
//   k  fur deep shadow
//   t  tabby stripe
//   w  white fur
//   x  white fur shadow
//   g  iris light
//   e  iris
//   f  iris dark
//   n  nose pink
//   m  pink shadow
//   i  inner ear pink
//   r  cheek blush
//   v  whiskers
//   y  eye shine
//   l  wood highlight
//   a  wood light
//   c  wood base
//   z  wood mid shadow
//   d  wood shadow
//   q  wood deep shadow

const CATS = [
  {
    id: 'tabby',
    name: 'Orange Tabby',
    description: 'Orange tabby with stripes on the head and tail',
    palette: {
      '.': null,
      o: '#24161a', // outline / pupil / mouth
      h: '#ffcf8a', // fur highlight
      j: '#f9b15f', // fur light
      b: '#f39234', // fur base
      u: '#de7a29', // fur mid shadow
      s: '#c8611d', // fur shadow
      k: '#93400f', // fur deep shadow
      t: '#a8481a', // tabby stripe
      w: '#fff4e2', // white fur
      x: '#efcf9f', // white fur shadow
      g: '#e2f9a6', // iris light
      e: '#8fd64c', // iris
      f: '#3f8a22', // iris dark
      n: '#f59ab0', // nose pink
      m: '#cf6585', // pink shadow
      i: '#f7a9bd', // inner ear pink
      r: '#f79154', // cheek blush
      v: '#fff6ea', // whiskers
      y: '#ffffff', // eye shine
      l: '#dba268', // wood highlight
      a: '#c48852', // wood light
      c: '#ad6d3c', // wood base
      z: '#945930', // wood mid shadow
      d: '#7a4524', // wood shadow
      q: '#4f2c17', // wood deep shadow
    },
  },
  {
    id: 'black',
    name: 'Black Cat',
    description: 'Black cat with yellow eyes',
    palette: {
      '.': null,
      o: '#08080d', // outline / pupil / mouth
      h: '#6f6f98', // fur highlight
      j: '#565678', // fur light
      b: '#3d3d58', // fur base
      u: '#34344c', // fur mid shadow
      s: '#2a2a40', // fur shadow
      k: '#1a1a2a', // fur deep shadow
      t: '#2a2a40', // tabby stripe
      w: '#f2f2f8', // white fur
      x: '#c4c4d4', // white fur shadow
      g: '#fff3a8', // iris light
      e: '#ffd23e', // iris
      f: '#d08a12', // iris dark
      n: '#f093ab', // nose pink
      m: '#b85a78', // pink shadow
      i: '#e99ab0', // inner ear pink
      r: '#815a73', // cheek blush
      v: '#c9c9dc', // whiskers
      y: '#ffffff', // eye shine
      l: '#dba268', // wood highlight
      a: '#c48852', // wood light
      c: '#ad6d3c', // wood base
      z: '#945930', // wood mid shadow
      d: '#7a4524', // wood shadow
      q: '#4f2c17', // wood deep shadow
    },
  },
  {
    id: 'grey',
    name: 'Grey & White',
    description: 'Grey and white cat with green eyes',
    palette: {
      '.': null,
      o: '#181a24', // outline / pupil / mouth
      h: '#d4d9e6', // fur highlight
      j: '#b6bccc', // fur light
      b: '#979eb2', // fur base
      u: '#82899e', // fur mid shadow
      s: '#6d748a', // fur shadow
      k: '#4b5166', // fur deep shadow
      t: '#6d748a', // tabby stripe
      w: '#fbfcff', // white fur
      x: '#cdd2df', // white fur shadow
      g: '#c4f8d2', // iris light
      e: '#4fd47e', // iris
      f: '#1f8a4c', // iris dark
      n: '#f59ab0', // nose pink
      m: '#cf6585', // pink shadow
      i: '#f7a9bd', // inner ear pink
      r: '#bb9db1', // cheek blush
      v: '#ffffff', // whiskers
      y: '#ffffff', // eye shine
      l: '#dba268', // wood highlight
      a: '#c48852', // wood light
      c: '#ad6d3c', // wood base
      z: '#945930', // wood mid shadow
      d: '#7a4524', // wood shadow
      q: '#4f2c17', // wood deep shadow
    },
  },
];

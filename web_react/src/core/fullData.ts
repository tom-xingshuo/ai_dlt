/** 生成大乐透前区全量组合 C(35,5)=324632 组, 每组升序。 */
export function generateGroups(): number[][] {
  const groups: number[][] = [];
  for (let a = 1; a <= 31; a += 1) {
    for (let b = a + 1; b <= 32; b += 1) {
      for (let c = b + 1; c <= 33; c += 1) {
        for (let d = c + 1; d <= 34; d += 1) {
          for (let e = d + 1; e <= 35; e += 1) {
            groups.push([a, b, c, d, e]);
          }
        }
      }
    }
  }
  return groups;
}

export const TOTAL_GROUPS = 324632;

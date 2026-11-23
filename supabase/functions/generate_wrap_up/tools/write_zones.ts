// Writes time_zones.json (#461): every IANA zone's country, from the tz
// database's zone.tab. Run when the tz database changes:
//
//   deno run --allow-read --allow-write tools/write_zones.ts \
//     [/usr/share/zoneinfo/zone.tab]
const path = Deno.args[0] ?? "/usr/share/zoneinfo/zone.tab";
const countries: Record<string, string[]> = {};
for (const line of (await Deno.readTextFile(path)).split("\n")) {
  if (!line || line.startsWith("#")) continue;
  const [code, , zone] = line.split("\t");
  (countries[code] ??= []).push(zone);
}
const sorted = Object.fromEntries(
  Object.keys(countries).sort().map((c) => [c, countries[c]]),
);
await Deno.writeTextFile(
  new URL("../time_zones.json", import.meta.url),
  JSON.stringify({ source: "tzdb zone.tab", countries: sorted }, null, 1) +
    "\n",
);
console.log(`${Object.keys(sorted).length} countries`);

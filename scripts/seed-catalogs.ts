import 'dotenv/config';
import { db } from '../src/lib/db/drizzle';
import { containerPresets, jarVariants } from '../src/lib/db/schema';
import { eq, sql } from 'drizzle-orm';

async function main() {
	// container_presets — per-row insert, stringify JSON, ignore dup key errors
	const presets = [
		{
			key: 'monotub_66l',
			containerType: 'monotub',
			label: '66 L tote',
			defaultsJson: { length_cm: 60, width_cm: 40, height_cm: 30, filter: 'hepa_sticker' },
			active: true
		},
		{
			key: 'shoebox_6qt',
			containerType: 'tray',
			label: '6 Qt shoebox',
			defaultsJson: { length_cm: 32, width_cm: 20, height_cm: 12 },
			active: true
		},
		{
			key: 'bag_medium',
			containerType: 'bag',
			label: 'Unicorn-style bag (M)',
			defaultsJson: { volume_l: 3, filter_patch_size_mm: 20, thickness_mil: 3 },
			active: true
		},
		{
			key: 'tray_9x13in',
			containerType: 'tray',
			label: '9×13 in aluminum tray',
			defaultsJson: { length_cm: 33, width_cm: 23, height_cm: 5 },
			active: true
		}
	];

	let presetInserted = 0,
		presetSkipped = 0;
	for (const p of presets) {
		const row = { ...p, defaultsJson: JSON.stringify(p.defaultsJson) } as any; // column name in DB is "defaults"
		try {
			await db.insert(containerPresets).values(row);
			presetInserted++;
		} catch (e: any) {
			const msg = String(e?.message ?? e);
			if (/UNIQUE|PRIMARY KEY|constraint/i.test(msg)) presetSkipped++;
			else throw e;
		}
	}

	const [{ count: totalPresets }] = await db
		.select({ count: sql<number>`COUNT(*)` })
		.from(containerPresets);

	// jar_variants — check-by-label to avoid dupes
	const jars = [
		{ label: 'Half Pint Regular', sizeMl: 236, mouth: 'narrow', heightMm: 85, diameterMm: 70 },
		{ label: 'Pint Wide Mouth', sizeMl: 473, mouth: 'wide', heightMm: 125, diameterMm: 85 },
		{ label: 'Quart Wide Mouth', sizeMl: 946, mouth: 'wide', heightMm: 170, diameterMm: 90 }
	];
	let jarInserted = 0,
		jarSkipped = 0;
	for (const j of jars) {
		const [exists] = await db
			.select({ id: jarVariants.id })
			.from(jarVariants)
			.where(eq(jarVariants.label, j.label))
			.limit(1);
		if (exists) {
			jarSkipped++;
			continue;
		}
		await db.insert(jarVariants).values(j);
		jarInserted++;
	}
	const [{ count: totalJars }] = await db
		.select({ count: sql<number>`COUNT(*)` })
		.from(jarVariants);

	console.log(
		JSON.stringify(
			{
				ok: true,
				inserted: { container_presets: presetInserted, jar_variants: jarInserted },
				skipped: { container_presets: presetSkipped, jar_variants: jarSkipped },
				totals: { container_presets: Number(totalPresets), jar_variants: Number(totalJars) }
			},
			null,
			2
		)
	);
}

main().catch((e) => {
	console.error(e);
	process.exit(1);
});

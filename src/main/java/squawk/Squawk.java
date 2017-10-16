package squawk;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.List;

public class Squawk
{
	public static File base;
	public static File patches;
	public static File compile;

	public static void main(String[] arg)
	{
		setup();

		try
		{
			buildPatch();
		}

		catch(IOException e)
		{
			e.printStackTrace();
		}
	}

	public static void applyAllPatches() throws IOException
	{
		int latest = getLatestPatch();
		int v = 1;

		System.out.println("Applying " + latest + " patches");

		while(v <= latest)
		{
			File f = new File(patches, "P." + v);

			if(f.exists())
			{
				System.out.println("# APPLY P." + v);
				Patch p = new Patch(v, compile);
				p.applyPatch(f);
			}

			else
			{
				System.out.println("# Skipping P." + v + " (MISSING)");
			}

			v++;
		}
	}

	public static void buildPatch() throws IOException
	{
		Patch p = new Patch(getLatestPatch() + 1, base);
		applyAllPatches();

		for(File i : files(base))
		{
			String dpath = i.getAbsolutePath();
			String dbase = base.getAbsolutePath();
			String target = new File(dbase).toURI().relativize(new File(dpath).toURI()).getPath();

			File j = new File(compile, target);

			if(j.exists() && j.isDirectory())
			{
				System.out.println("$ " + target + " was a directory. Now it's a file. This is going to be annoying...");
				System.out.println("$ " + target + " was deleted (folder fix).");
				p.getPatches().add(new DeletePatchObject(target));

				System.out.println("$ " + target + " was created (folder fix).");
				p.getPatches().add(new WritePatchObject(target));
			}

			else if(j.exists() && !j.isDirectory())
			{
				if(j.length() != i.length())
				{
					System.out.println("$ " + target + " was modified.");
					p.getPatches().add(new WritePatchObject(target));
				}
			}

			else if(!j.exists())
			{
				System.out.println("$ " + target + " was created.");
				p.getPatches().add(new WritePatchObject(target));
			}
		}

		for(File i : files(compile))
		{
			String dpath = i.getAbsolutePath();
			String dbase = compile.getAbsolutePath();
			String target = new File(dbase).toURI().relativize(new File(dpath).toURI()).getPath();

			File j = new File(base, target);

			if(!j.exists())
			{
				System.out.println("$ " + target + " was deleted.");
				p.getPatches().add(new DeletePatchObject(target));
			}
		}

		p.buildPatch(new File(patches, "P." + p.getVersion()));
		System.out.println("Patch created, Applying all patches");
		applyAllPatches();
		updateMetadata();
	}

	public static void updateMetadata() throws IOException
	{
		File f = new File("patch.mda");
		PrintWriter pw = new PrintWriter(new FileWriter(f));
		pw.println("latest: " + getLatestPatch());
		pw.close();
		System.out.println("Updated patch metadata");
	}

	public static int getLatestPatch()
	{
		int max = 0;

		for(File i : patches.listFiles())
		{
			if(i.getName().startsWith("P."))
			{
				int ver = Integer.valueOf(i.getName().split("\\.")[1]);

				if(ver > max)
				{
					max = ver;
				}
			}
		}

		return max;
	}

	public static void setup()
	{
		compile = new File("compile");
		compile.mkdirs();
		base = new File("base");
		base.mkdirs();
		patches = new File("patches");
		patches.mkdirs();
	}

	public static List<File> files(File dir)
	{
		List<File> ff = new ArrayList<File>();

		for(File i : dir.listFiles())
		{
			if(i.isDirectory())
			{
				ff.addAll(files(i));
			}

			else
			{
				ff.add(i);
			}
		}

		return ff;
	}
}

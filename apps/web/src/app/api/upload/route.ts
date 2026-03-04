import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { generatePresignedUploadUrl, generatePhotoKey } from "@/lib/r2";
import { z } from "zod";

const uploadSchema = z.object({
  filename: z.string().min(1),
  contentType: z.string().startsWith("image/"),
  size: z.number().max(20 * 1024 * 1024, "File too large (max 20MB)"),
});

export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();

    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const body = await request.json();
    const validation = uploadSchema.safeParse(body);

    if (!validation.success) {
      return NextResponse.json(
        { error: validation.error.errors[0].message },
        { status: 400 }
      );
    }

    const { filename, contentType } = validation.data;
    const key = generatePhotoKey(user.id, filename);
    const uploadUrl = await generatePresignedUploadUrl(key, contentType);

    return NextResponse.json({ uploadUrl, key });
  } catch (error) {
    console.error("Upload error:", error);
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
}

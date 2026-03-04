/**
 * @jest-environment node
 */
import { GET } from "@/app/api/health/route";

describe("GET /api/health", () => {
  it("returns status ok", async () => {
    const response = await GET();
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.status).toBe("ok");
    expect(data.service).toBe("photographes.ci");
    expect(data.timestamp).toBeDefined();
  });
});

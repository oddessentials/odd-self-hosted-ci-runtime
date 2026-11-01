import { copyFileSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { Marked } from "marked";

const here = new URL("./", import.meta.url);
const out = new URL("../_site/", here);
const md = readFileSync(new URL("agents.md", here), "utf8");

const slug = (s) =>
  s.replace(/<[^>]+>/g, "").toLowerCase().replace(/[^\w\s-]/g, "").trim().replace(/\s+/g, "-");

const toc = [];
const marked = new Marked({
  gfm: true,
  renderer: {
    heading({ tokens, depth }) {
      const text = this.parser.parseInline(tokens);
      const id = slug(text);
      if (depth === 2) toc.push({ id, text });
      return `<h${depth} id="${id}"><a href="#${id}">${text}</a></h${depth}>\n`;
    },
  },
});

const body = await marked.parse(md);
const title = /^# (.+)$/m.exec(md)[1];
const nav = toc.map((t) => `    <li><a href="#${t.id}">${t.text}</a></li>`).join("\n");
const html = readFileSync(new URL("template.html", here), "utf8")
  .replaceAll("{{title}}", title)
  .replace("{{nav}}", () => nav)
  .replace("{{body}}", () => body);

mkdirSync(out, { recursive: true });
writeFileSync(new URL("index.html", out), html);
copyFileSync(new URL("agents.md", here), new URL("agents.md", out));
writeFileSync(new URL(".nojekyll", out), "");

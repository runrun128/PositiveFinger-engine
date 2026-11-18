#!/bin/bash
set -e

echo "=== PositiveFinger NLP Lab ==="

mkdir -p vendor

if [ ! -d vendor/kuromoji ]; then
  git clone --depth 1 https://github.com/takuyaa/kuromoji.js.git vendor/kuromoji
fi

mkdir -p licenses/kuromoji

cp vendor/kuromoji/LICENSE-2.0.txt licenses/kuromoji/ 2>/dev/null || true
cp vendor/kuromoji/NOTICE.md licenses/kuromoji/ 2>/dev/null || true

if [ -f index.html ]; then
  cp index.html "index.backup.$(date +%Y%m%d%H%M%S).html"
fi

cat > index.html <<'HTML'
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>PositiveFinger NLP Lab</title>
<style>
*{box-sizing:border-box}
body{margin:0;background:#f6f7f9;color:#20242c;font-family:-apple-system,BlinkMacSystemFont,sans-serif}
header{background:white;border-bottom:1px solid #e8eaf0;padding:20px 5%;font-weight:800}
header span{color:#536dfe}
main{max-width:1000px;margin:40px auto;padding:0 20px}
.card{background:white;border:1px solid #e8eaf0;border-radius:12px;padding:24px;margin-top:22px}
.sub{color:#858b98;font-size:13px}
textarea{width:100%;height:130px;padding:15px;border:1px solid #ddd;border-radius:8px;font-size:15px}
button{padding:12px 20px;border:0;border-radius:7px;cursor:pointer;font-weight:bold}
.primary{background:#536dfe;color:white}
table{width:100%;border-collapse:collapse;font-size:13px}
td,th{text-align:left;padding:12px;border-bottom:1px solid #eee}
th{color:#858b98}
.grid{display:grid;grid-template-columns:repeat(3,1fr);gap:12px;margin-top:20px}
.metric{background:white;border:1px solid #e8eaf0;border-radius:10px;padding:18px}
.metric strong{display:block;font-size:24px;margin-top:8px}
.tag{background:#edf0ff;color:#536dfe;padding:4px 7px;border-radius:5px}
#result{display:none}
@media(max-width:600px){.grid{grid-template-columns:1fr}.card{padding:16px}}
</style>
</head>
<body>
<header>Positive<span>Finger</span> / NLP LAB</header>
<main>
<h1>Japanese Morphological Analyzer</h1>
<p class="sub">Local Japanese NLP Processing Environment</p>

<section class="card">
<h3>TEXT INPUT</h3>
<textarea id="input">今日は本当に楽しかった。友達が優しくしてくれて嬉しかった！</textarea>
<p><button class="primary" onclick="analyze()">ANALYZE →</button></p>
<p class="sub" id="status">エンジンを初期化しています...</p>
</section>

<div id="result">
<div class="grid">
<div class="metric">TOTAL TOKENS<strong id="total">0</strong></div>
<div class="metric">NOUNS<strong id="nouns">0</strong></div>
<div class="metric">VERBS / ADJECTIVES<strong id="verbs">0</strong></div>
</div>
<section class="card">
<h3>MORPHOLOGICAL ANALYSIS</h3>
<div style="overflow-x:auto">
<table>
<thead><tr><th>表層形</th><th>基本形</th><th>品詞</th><th>詳細</th><th>読み</th></tr></thead>
<tbody id="tokens"></tbody>
</table>
</div>
</section>
<section class="card">
<h3>RAW DATA</h3>
<pre id="raw" style="white-space:pre-wrap;overflow-wrap:anywhere"></pre>
</section>
</div>
</main>

<script src="./vendor/kuromoji/build/kuromoji.js"></script>
<script>
let tokenizer = null;
let initPromise = null;

function initialize(){
  if(initPromise) return initPromise;
  initPromise = new Promise((resolve,reject)=>{
    if(!window.kuromoji){
      reject(new Error("Kuromoji.jsを読み込めません。ファイル構成を確認してください。"));
      return;
    }
    kuromoji.builder({dicPath:"./vendor/kuromoji/dict/"}).build((err,t)=>{
      if(err){reject(err);return;}
      tokenizer=t;
      resolve(t);
    });
  });
  return initPromise;
}

function esc(s){
  return String(s ?? "").replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
}

async function analyze(){
  const status=document.getElementById("status");
  try{
    await initialize();
    const input=document.getElementById("input").value.trim();
    if(!input){status.textContent="文章を入力してください";return;}
    const tokens=tokenizer.tokenize(input);
    const nouns=tokens.filter(t=>t.pos==="名詞").length;
    const verbs=tokens.filter(t=>t.pos==="動詞"||t.pos==="形容詞").length;
    document.getElementById("total").textContent=tokens.length;
    document.getElementById("nouns").textContent=nouns;
    document.getElementById("verbs").textContent=verbs;
    document.getElementById("tokens").innerHTML=tokens.map(t=>`
      <tr>
        <td><strong>${esc(t.surface_form)}</strong></td>
        <td>${esc(t.basic_form)}</td>
        <td><span class="tag">${esc(t.pos)}</span></td>
        <td>${esc(t.pos_detail_1)}</td>
        <td>${esc(t.reading)}</td>
      </tr>
    `).join("");
    document.getElementById("raw").textContent=JSON.stringify(tokens,null,2);
    document.getElementById("result").style.display="block";
    status.textContent="解析完了";
  }catch(e){
    status.textContent="エラー: "+e.message;
    console.error(e);
  }
}

initialize().then(()=>{
  document.getElementById("status").textContent="Kuromoji.js READY";
}).catch(e=>{
  document.getElementById("status").textContent="初期化エラー: "+e.message;
  console.error(e);
});
</script>
</body>
</html>
HTML

echo ""
echo "=== ファイル確認 ==="

test -f vendor/kuromoji/build/kuromoji.js
test -d vendor/kuromoji/dict
test -f index.html

echo "セットアップ完了"

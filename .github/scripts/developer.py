#!/usr/bin/env python3
"""
Developer: 最古のIssueを1件選んでSwiftUIコードを実装しPRを作成する
"""
import os
import json
import re
import subprocess
import urllib.request
import urllib.error
import glob

ANTHROPIC_API_KEY = os.environ["ANTHROPIC_API_KEY"]
GITHUB_TOKEN = os.environ["GITHUB_TOKEN"]
REPO = "OfficeGakuNet/JisuitaApp"


def github_request(method, path, data=None):
    url = f"https://api.github.com{path}"
    headers = {
        "Accept": "application/vnd.github+json",
        "Authorization": f"Bearer {GITHUB_TOKEN}",
        "Content-Type": "application/json",
    }
    body = json.dumps(data).encode() if data else None
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        print(f"GitHub API error {e.code}: {e.read().decode()}")
        return None


def claude_request(prompt):
    url = "https://api.anthropic.com/v1/messages"
    headers = {
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
        "Content-Type": "application/json",
    }
    data = {
        "model": "claude-sonnet-4-6",
        "max_tokens": 8000,
        "messages": [{"role": "user", "content": prompt}],
    }
    req = urllib.request.Request(
        url, data=json.dumps(data).encode(), headers=headers, method="POST"
    )
    with urllib.request.urlopen(req) as resp:
        result = json.loads(resp.read())
        return result["content"][0]["text"]


def run(cmd, check=True):
    print(f"$ {cmd}")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if result.stdout:
        print(result.stdout)
    if result.stderr:
        print(result.stderr)
    if check and result.returncode != 0:
        raise RuntimeError(f"コマンド失敗: {cmd}")
    return result.stdout.strip()


def read_file(path):
    try:
        with open(path, encoding="utf-8") as f:
            return f.read()
    except Exception:
        return ""


def get_open_prs_issues():
    prs = github_request("GET", f"/repos/{REPO}/pulls?state=open&per_page=100") or []
    linked = set()
    for pr in prs:
        body = pr.get("body", "") or ""
        for m in re.findall(r"closes\s+#(\d+)", body, re.IGNORECASE):
            linked.add(int(m))
    return linked


def main():
    # 未対応のIssueを取得
    issues = github_request("GET", f"/repos/{REPO}/issues?state=open&per_page=50&sort=created&direction=asc") or []
    linked_issues = get_open_prs_issues()

    target = None
    for issue in issues:
        if issue["number"] not in linked_issues:
            target = issue
            break

    if not target:
        print("対応すべきIssueがありません")
        return

    issue_number = target["number"]
    issue_title = target["title"]
    issue_body = target.get("body", "")
    print(f"対応Issue: #{issue_number} {issue_title}")

    # 既存コードを収集
    existing_code = {}
    for path in sorted(glob.glob("JisuitaApp/*.swift"))[:8]:
        name = os.path.basename(path)
        existing_code[name] = read_file(path)[:2000]

    code_summary = "\n\n".join(
        f"=== {n} ===\n{c}" for n, c in existing_code.items()
    )

    spec = read_file("ai_nutritionist_app_design.md")[:2000]

    # Claudeに実装を依頼
    prompt = f"""あなたはiOSアプリ「JisuitaApp」のSwiftUI開発者です。
以下のGitHub Issueを解決するコードを実装してください。

【Issue #{issue_number}】{issue_title}
{issue_body}

【コーディング規則】
- SwiftUI のみ（UIKit不可）
- メインカラー: Color(hex: "1D9E75")
- 背景: Color(.systemGroupedBackground)
- コメントは本当に必要な場合のみ
- 既存ファイルのスタイルに合わせる

【仕様書（抜粋）】
{spec}

【既存コード（抜粋）】
{code_summary}

以下のJSON形式で返してください（他のテキスト不要）：
{{
  "files": [
    {{
      "path": "JisuitaApp/ファイル名.swift",
      "action": "create" または "modify",
      "content": "Swiftコード全体"
    }}
  ],
  "pr_description": "PRの説明文（日本語）"
}}"""

    print("Claudeに実装を依頼中...")
    response = claude_request(prompt)

    # JSONを抽出
    try:
        start = response.find("{")
        end = response.rfind("}") + 1
        result = json.loads(response[start:end])
    except Exception as e:
        print(f"JSON解析エラー: {e}")
        print(response[:500])
        return

    # ブランチ作成
    branch = f"fix/issue-{issue_number}-{re.sub(r'[^a-z0-9]', '-', issue_title.lower())[:30]}"
    run("git config user.email 'github-actions[bot]@users.noreply.github.com'")
    run("git config user.name 'github-actions[bot]'")
    run(f"git checkout -b {branch}")

    # ファイルを書き込む
    for file_info in result.get("files", []):
        path = file_info["path"]
        content = file_info["content"]
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"書き込み: {path}")

    # コミット＆プッシュ
    run("git add JisuitaApp/")
    run(f"git commit -m 'fix: {issue_title} (closes #{issue_number})'")
    run(f"git push --force origin {branch}")

    # PR作成
    pr_body = f"closes #{issue_number}\n\n## 実装内容\n{result.get('pr_description', '')}"
    pr = github_request(
        "POST",
        f"/repos/{REPO}/pulls",
        {
            "title": f"{issue_title}",
            "body": pr_body,
            "head": branch,
            "base": "main",
        },
    )
    if pr:
        print(f"PR作成完了: {pr['html_url']}")
    else:
        print("PR作成失敗")


if __name__ == "__main__":
    main()

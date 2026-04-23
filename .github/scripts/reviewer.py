#!/usr/bin/env python3
"""
Reviewer: コードを分析してGitHub Issueを作成する
"""
import os
import json
import urllib.request
import urllib.error
import glob

ANTHROPIC_API_KEY = os.environ["ANTHROPIC_API_KEY"]
GITHUB_TOKEN = os.environ["GITHUB_TOKEN"]
REPO = "OfficeGakuNet/JisuitaApp"


def read_file(path):
    try:
        with open(path, encoding="utf-8") as f:
            return f.read()
    except Exception:
        return ""


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
        "max_tokens": 4000,
        "messages": [{"role": "user", "content": prompt}],
    }
    req = urllib.request.Request(
        url, data=json.dumps(data).encode(), headers=headers, method="POST"
    )
    with urllib.request.urlopen(req) as resp:
        result = json.loads(resp.read())
        return result["content"][0]["text"]


def get_existing_issue_titles():
    issues = github_request("GET", f"/repos/{REPO}/issues?state=open&per_page=100") or []
    return {issue["title"] for issue in issues}


def main():
    # 仕様書を読む
    spec = read_file("ai_nutritionist_app_design.md")

    # Swiftファイルを読む
    swift_files = {}
    for path in sorted(glob.glob("JisuitaApp/*.swift")):
        name = os.path.basename(path)
        content = read_file(path)
        swift_files[name] = content[:3000]  # 長すぎる場合は先頭3000文字

    swift_summary = "\n\n".join(
        f"=== {name} ===\n{content}" for name, content in swift_files.items()
    )

    existing_titles = get_existing_issue_titles()
    print(f"既存のIssue数: {len(existing_titles)}")

    # Claudeにレビューを依頼
    prompt = f"""あなたはiOSアプリ「JisuitaApp」のコードレビュアーです。
以下の仕様書と実装コードを比較して、品質改善が必要な点をJSON形式でリストアップしてください。

【仕様書】
{spec[:3000]}

【実装コード（抜粋）】
{swift_summary[:6000]}

【既存のIssueタイトル（重複作成しないこと）】
{chr(10).join(existing_titles) if existing_titles else "なし"}

以下の観点でIssueを作成してください：
- プレースホルダーのまま未実装の画面
- 仕様書に記載されているが実装されていない機能
- モックデータのままで実データと繋がっていない箇所
- 画面間のナビゲーションが繋がっていない箇所

JSON形式で返してください（他のテキスト不要）：
[
  {{
    "title": "Issueのタイトル（具体的に）",
    "body": "## 問題\\n...\\n\\n## 対応内容\\n...\\n\\n## 該当ファイル\\n..."
  }}
]

最大5件まで。既存Issueと重複するタイトルは含めないこと。"""

    print("Claudeに分析を依頼中...")
    response = claude_request(prompt)

    # JSONを抽出
    try:
        start = response.find("[")
        end = response.rfind("]") + 1
        issues_data = json.loads(response[start:end])
    except Exception as e:
        print(f"JSON解析エラー: {e}")
        print(f"レスポンス: {response[:500]}")
        return

    print(f"新規Issue候補: {len(issues_data)}件")

    created = 0
    for issue in issues_data:
        title = issue.get("title", "").strip()
        body = issue.get("body", "").strip()

        if not title or title in existing_titles:
            print(f"スキップ（重複）: {title}")
            continue

        result = github_request(
            "POST",
            f"/repos/{REPO}/issues",
            {"title": title, "body": body, "labels": ["enhancement"]},
        )
        if result:
            print(f"Issue作成: #{result['number']} {title}")
            created += 1

    print(f"完了: {created}件のIssueを作成しました")


if __name__ == "__main__":
    main()

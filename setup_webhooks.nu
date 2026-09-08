
#!/usr/bin/env nu

def main [] {
    let target_user = "minerva-jupiter"
    let portal_repo = "stagit4github"
    let pat_token = $env.GH_PAT_TOKEN? | default ""

    if ($pat_token | is-empty) {
        print "Error: GH_PAT_TOKEN environment variable is not set."
        return
    }

    let hook_url = $"https://api.github.com/repos/($target_user)/($portal_repo)/dispatches"

    # 全リポジトリ一覧を取得（ポータル用リポジトリを除外）
    let repos = (
        gh repo list $target_user --limit 200 --json name
        | from json
        | get name
        | where $it != $portal_repo
    )

    print $"Target Repositories Count: ($repos | length)"
    print "=========================================="

    mut current = 1
    let total = ($repos | length)

    for repo in $repos {
        print $"\n[($current)/($total)] >>> Processing: ($repo)"

        let payload = ({
            name: "web",
            active: true,
            events: ["push"],
            config: {
                url: $hook_url,
                content_type: "json",
                insecure_ssl: "0"
            }
        } | to json)

        # do -i で gh api のエラー（422等）を無視してレスポンス/エラーメッセージを垂れ流し、次のループへ進む
        do -i {
            $payload | gh api $"repos/($target_user)/($repo)/hooks" --input - -H $"Authorization: Bearer ($pat_token)"
        }

        $current += 1
    }

    print "\n=========================================="
    print "All repositories processed."
}

task UpdateChangelog {
    param(
        [string]$ChangelogPath = "./CHANGELOG.md",
        [string]$BaseBranch = "main"  # The base branch to compare commits against
    )

    # Ensure Git is available
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "Git is not installed or not available in the system's PATH."
    }

    # Get the current branch
    $currentBranch = git rev-parse --abbrev-ref HEAD
    if ($currentBranch -eq $BaseBranch) {
        throw "You are on the base branch ($BaseBranch). This task should only be run on feature or non-main branches."
    }

    # Function to get conventional commits
    function Get-ConventionalCommits {
        param(
            [string]$FromBranch
        )

        # Adjust the commit message pattern for conventional commits
        $commitPattern = '^(feat|fix|docs|style|refactor|perf|test|chore)\((.*)\): (.*)$'
        $commits = git log $FromBranch..HEAD --pretty=format:"%s" |
                   Where-Object { $_ -match $commitPattern } |
                   ForEach-Object {
                       if ($_ -match $commitPattern) {
                           @{
                               Type = $matches[1]
                               Scope = $matches[2]
                               Description = $matches[3]
                           }
                       }
                   }
        return $commits
    }

    # Get conventional commits between the base branch (main) and the current branch
    $commits = Get-ConventionalCommits -FromBranch $BaseBranch

    if ($commits.Count -eq 0) {
        Write-Host "No conventional commits found between $BaseBranch and $currentBranch."
        return
    }

    # Initialize changelog sections for Keep a Changelog format
    $addedSection = @()
    $changedSection = @()
    $fixedSection = @()
    $otherSection = @()

    # Categorize commits according to the Keep a Changelog format
    # Categorize commits according to the Keep a Changelog format
foreach ($commit in $commits) {
    switch ($commit.Type) {
        'feat' {
            $addedSection += "- **$($commit.Scope)**: $($commit.Description)"
        }
        'fix' {
            $fixedSection += "- **$($commit.Scope)**: $($commit.Description)"
        }
        'docs' {
            $otherSection += "- **$($commit.Scope)**: $($commit.Description) ($commit.Type)"
        }
        'style' {
            $otherSection += "- **$($commit.Scope)**: $($commit.Description) ($commit.Type)"
        }
        'refactor' {
            $otherSection += "- **$($commit.Scope)**: $($commit.Description) ($commit.Type)"
        }
        'perf' {
            $otherSection += "- **$($commit.Scope)**: $($commit.Description) ($commit.Type)"
        }
        'test' {
            $otherSection += "- **$($commit.Scope)**: $($commit.Description) ($commit.Type)"
        }
        'chore' {
            $otherSection += "- **$($commit.Scope)**: $($commit.Description) ($commit.Type)"
        }
        default {
            $otherSection += "- **$($commit.Scope)**: $($commit.Description) ($commit.Type)"
        }
    }
}

    # Read the existing changelog if it exists
    $changelogContent = Get-Content -Path $ChangelogPath -ErrorAction SilentlyContinue
    if (-not $changelogContent) {
        $changelogContent = @()
    }

    # Find the "Unreleased" section or create it if it doesn't exist
    $unreleasedSectionExists = $false
    $newChangelogEntries = @()
    foreach ($line in $changelogContent) {
        if ($line -match '## \[Unreleased\]') {
            $unreleasedSectionExists = $true
            $newChangelogEntries += $line  # Preserve the "Unreleased" header

            # Add categorized commits under "Unreleased"
            if ($addedSection.Count -gt 0) {
                $newChangelogEntries += "### Added"
                $newChangelogEntries += $addedSection
                $newChangelogEntries += ""
            }
            if ($changedSection.Count -gt 0) {
                $newChangelogEntries += "### Changed"
                $newChangelogEntries += $changedSection
                $newChangelogEntries += ""
            }
            if ($fixedSection.Count -gt 0) {
                $newChangelogEntries += "### Fixed"
                $newChangelogEntries += $fixedSection
                $newChangelogEntries += ""
            }
            if ($otherSection.Count -gt 0) {
                $newChangelogEntries += "### Other"
                $newChangelogEntries += $otherSection
                $newChangelogEntries += ""
            }
        } else {
            $newChangelogEntries += $line
        }
    }

    # If no "Unreleased" section exists, create it at the top
    if (-not $unreleasedSectionExists) {
        $newChangelogEntries = @(
            "## [Unreleased]",
            ""
        ) + $addedSection + $changedSection + $fixedSection + $otherSection + "" + $newChangelogEntries
    }

    # Write the updated changelog
    $newChangelogEntries | Set-Content -Path $ChangelogPath

    Write-Host "Changelog updated successfully for branch '$currentBranch' at $ChangelogPath"
}

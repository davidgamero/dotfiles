#!/usr/bin/python3
# <bitbar.title>Copilot Monthly Usage</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>david</bitbar.author>
# <bitbar.desc>Shows the percentage of your monthly Copilot allowance used.</bitbar.desc>
# <swiftbar.refreshOnOpen>true</swiftbar.refreshOnOpen>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>

# Credentials stay machine-local; only quota information is displayed.

import calendar
import json
import math
import os
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path


def credentials():
    data_dir = Path(os.environ.get('XDG_DATA_HOME', Path.home() / '.local/share'))
    config_dir = Path(os.environ.get('XDG_CONFIG_HOME', Path.home() / '.config'))
    try:
        auth = json.loads((data_dir / 'opencode/auth.json').read_text())
        copilot = auth.get('github-copilot', {})
        token = copilot.get('refresh') or copilot.get('access')
        if token:
            return token
    except (OSError, ValueError, TypeError, AttributeError):
        pass
    for name in ('apps.json', 'hosts.json'):
        try:
            accounts = json.loads((config_dir / 'github-copilot' / name).read_text())
            for host, account in accounts.items():
                if host.split(':')[0] == 'github.com' and account.get('oauth_token'):
                    return account['oauth_token']
        except (OSError, ValueError, TypeError, AttributeError):
            pass
    raise ValueError('Sign in to GitHub Copilot in OpenCode to view usage.')


def cycle_elapsed(reset, now):
    if not reset:
        return None
    try:
        end = datetime.fromisoformat(reset.replace('Z', '+00:00'))
        if end.tzinfo is None:
            end = end.replace(tzinfo=timezone.utc)
        month = end.month - 1 or 12
        year = end.year - (end.month == 1)
        day = min(end.day, calendar.monthrange(year, month)[1])
        start = end.replace(year=year, month=month, day=day)
        if not start <= now < end:
            return None
        return (now - start).total_seconds() / (end - start).total_seconds() * 100
    except (ValueError, TypeError, AttributeError):
        return None


def pace_color(used, elapsed):
    if used >= 100:
        return '#FF453A', 'Allowance fully used'
    if used <= elapsed:
        return '#34C759', 'At or below monthly pace'
    if used <= elapsed * 1.25:
        return '#FFD60A', 'Up to 25% ahead of monthly pace'
    if used <= elapsed * 1.5:
        return '#FF9500', '25–50% ahead of monthly pace'
    return '#FF453A', 'Over 50% ahead of monthly pace'


def usage():
    request = urllib.request.Request(
        'https://api.github.com/copilot_internal/user',
        headers={
            'Authorization': 'token ' + credentials(),
            'Accept': 'application/json',
            'User-Agent': 'SwiftBar-Copilot-Usage',
        },
    )
    with urllib.request.urlopen(request, timeout=10) as response:
        data = json.load(response)
    quota = data.get('quota_snapshots', {}).get('premium_interactions')
    if not isinstance(quota, dict):
        raise ValueError('GitHub did not return a monthly Copilot allowance.')
    reset = data.get('quota_reset_date_utc') or data.get('quota_reset_date')
    elapsed = cycle_elapsed(reset, datetime.now(timezone.utc))

    if quota.get('unlimited'):
        print('✨: ∞')
        print('---')
        print('Monthly Copilot allowance: unlimited')
    else:
        remaining = float(quota['percent_remaining'])
        if not math.isfinite(remaining) or not 0 <= remaining <= 100:
            raise ValueError('GitHub returned an invalid usage percentage.')
        used = 100 - remaining
        color, pace = pace_color(used, elapsed) if elapsed is not None else (None, None)
        style = f' | color={color}' if color else ''
        print(f'✨: {used:.1f}%{style}')
        print('---')
        print(f'Monthly Copilot allowance: {used:.1f}% used{style}')
        print(f'Remaining: {remaining:.1f}%')
        if elapsed is not None:
            print(f'Cycle elapsed: {elapsed:.1f}% · Time until reset: {100 - elapsed:.1f}%')
            print(f'{pace}{style}')
        else:
            print('Monthly pace unavailable: no current reset date.')

    if reset:
        print(f'Resets: {reset[:10]}' + (' (UTC)' if data.get('quota_reset_date_utc') else ''))
    print(f'Updated: {datetime.now():%H:%M:%S}')


try:
    usage()
except urllib.error.HTTPError as error:
    print('✨: --')
    print('---')
    print(f'Could not fetch Copilot usage (HTTP {error.code}).')
except (OSError, ValueError, KeyError, TypeError, AttributeError):
    print('✨: --')
    print('---')
    print('Copilot usage unavailable. Check your connection and Copilot sign-in.')

print('---')
print('Open Copilot settings | href=https://github.com/settings/copilot')
print('Refresh | refresh=true')

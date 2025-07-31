#!/usr/bin/env python3
import matplotlib
matplotlib.use('Agg')  # GUIバックエンドを使わない設定
import matplotlib.pyplot as plt
import numpy as np
import json
import sys
import os
from datetime import datetime, timedelta
import sqlite3

# 日本語フォントの設定を簡素化（macOSのデフォルトフォントを使用）
try:
    # macOSで利用可能なフォントを試す
    available_fonts = ['Hiragino Sans', 'Arial Unicode MS', 'AppleGothic', 'sans-serif']
    for font in available_fonts:
        try:
            plt.rcParams['font.family'] = font
            break
        except:
            continue
    else:
        # フォールバック
        plt.rcParams['font.family'] = 'sans-serif'
except:
    plt.rcParams['font.family'] = 'sans-serif'

def connect_to_db():
    """データベースに接続"""
    # 絶対パスを使用してデータベースに接続
    script_dir = os.path.dirname(os.path.abspath(__file__))
    db_path = os.path.join(script_dir, '..', '..', '..', 'storage', 'development.sqlite3')
    db_path = os.path.abspath(db_path)
    
    print(f"Trying to connect to database at: {db_path}")
    print(f"Database file exists: {os.path.exists(db_path)}")
    
    try:
        conn = sqlite3.connect(db_path)
        return conn
    except sqlite3.Error as e:
        print(f"Database connection error: {e}")
        return None

def get_match_statistics():
    """マッチング統計を取得"""
    conn = connect_to_db()
    if not conn:
        return None
    
    try:
        cursor = conn.cursor()
        
        # 総ユーザー数
        cursor.execute("SELECT COUNT(*) FROM users WHERE email != 'guest@example.com'")
        total_users = cursor.fetchone()[0]
        
        # マッチング済みユーザー数
        cursor.execute("""
            SELECT COUNT(DISTINCT user_id) 
            FROM (
                SELECT user_id FROM matches WHERE status = 1
                UNION
                SELECT target_user_id as user_id FROM matches WHERE status = 1
            )
        """)
        matched_users = cursor.fetchone()[0]
        
        # 総マッチ数
        cursor.execute("SELECT COUNT(*) FROM matches WHERE status = 1")
        total_matches = cursor.fetchone()[0]
        
        # アクティブな取引数
        cursor.execute("SELECT COUNT(*) FROM deals WHERE status IN (0, 1, 2)")
        active_deals = cursor.fetchone()[0]
        
        # 完了した取引数
        cursor.execute("SELECT COUNT(*) FROM deals WHERE status = 3")
        completed_deals = cursor.fetchone()[0]
        
        # 月別マッチング数（過去6ヶ月）
        cursor.execute("""
            SELECT 
                strftime('%Y-%m', created_at) as month,
                COUNT(*) as count
            FROM matches 
            WHERE status = 1 
                AND created_at >= date('now', '-6 months')
            GROUP BY strftime('%Y-%m', created_at)
            ORDER BY month
        """)
        monthly_matches = cursor.fetchall()
        
        conn.close()
        
        # マッチ率を計算
        match_rate = (matched_users / total_users * 100) if total_users > 0 else 0
        success_rate = (completed_deals / (active_deals + completed_deals) * 100) if (active_deals + completed_deals) > 0 else 0
        
        return {
            'total_users': total_users,
            'matched_users': matched_users,
            'match_rate': match_rate,
            'total_matches': total_matches,
            'active_deals': active_deals,
            'completed_deals': completed_deals,
            'success_rate': success_rate,
            'monthly_matches': monthly_matches
        }
        
    except sqlite3.Error as e:
        print(f"Database query error: {e}")
        if conn:
            conn.close()
        return None

def generate_match_rate_chart(stats):
    """マッチ率の円グラフを生成"""
    if not stats:
        return False
    
    # データ準備
    matched = stats['matched_users']
    unmatched = stats['total_users'] - matched
    
    labels = ['マッチ済み', '未マッチ']
    sizes = [matched, unmatched]
    colors = ['#4CAF50', '#E0E0E0']
    explode = (0.1, 0)  # マッチ済みを強調
    
    # グラフ作成
    fig, ax = plt.subplots(figsize=(8, 6))
    wedges, texts, autotexts = ax.pie(sizes, explode=explode, labels=labels, colors=colors,
                                      autopct='%1.1f%%', shadow=True, startangle=90)
    
    # スタイル調整
    for autotext in autotexts:
        autotext.set_color('white')
        autotext.set_fontweight('bold')
    
    ax.set_title(f'ユーザーマッチ率\n(総ユーザー数: {stats["total_users"]}人)', 
                fontsize=16, fontweight='bold', pad=20)
    
    # 統計情報を追加
    info_text = f"""マッチ率: {stats['match_rate']:.1f}%
総マッチ数: {stats['total_matches']}件
アクティブ取引: {stats['active_deals']}件
完了取引: {stats['completed_deals']}件
成功率: {stats['success_rate']:.1f}%"""
    
    plt.figtext(0.02, 0.02, info_text, fontsize=10, 
                bbox=dict(boxstyle="round,pad=0.3", facecolor="lightgray", alpha=0.8))
    
    # 保存パスを絶対パスで指定
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_path = os.path.join(script_dir, '..', '..', '..', 'app', 'assets', 'images', 'match_rate_chart.png')
    output_path = os.path.abspath(output_path)
    
    # publicディレクトリにもコピー
    public_path = os.path.join(script_dir, '..', '..', '..', 'public', 'match_rate_chart.png')
    public_path = os.path.abspath(public_path)
    
    # ディレクトリが存在しない場合は作成
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    os.makedirs(os.path.dirname(public_path), exist_ok=True)
    
    print(f"Saving chart to: {output_path}")
    plt.savefig(output_path, dpi=300, bbox_inches='tight', facecolor='white')
    
    print(f"Copying chart to: {public_path}")
    plt.savefig(public_path, dpi=300, bbox_inches='tight', facecolor='white')
    plt.close()
    
    return True

def generate_monthly_trend_chart(stats):
    """月別マッチングトレンドグラフを生成"""
    if not stats or not stats['monthly_matches']:
        return False
    
    # データ準備
    months = []
    counts = []
    
    for month, count in stats['monthly_matches']:
        months.append(month)
        counts.append(count)
    
    # 足りない月を補完
    if len(months) < 6:
        current_date = datetime.now()
        for i in range(6):
            month_str = (current_date - timedelta(days=30*i)).strftime('%Y-%m')
            if month_str not in months:
                months.insert(0, month_str)
                counts.insert(0, 0)
        
        # ソート
        combined = list(zip(months, counts))
        combined.sort()
        months, counts = zip(*combined)
    
    # グラフ作成
    fig, ax = plt.subplots(figsize=(10, 6))
    bars = ax.bar(months, counts, color='#2196F3', alpha=0.7)
    
    # データラベル追加
    for bar in bars:
        height = bar.get_height()
        if height > 0:
            ax.text(bar.get_x() + bar.get_width()/2., height,
                   f'{int(height)}',
                   ha='center', va='bottom', fontweight='bold')
    
    ax.set_title('月別マッチング数推移', fontsize=16, fontweight='bold', pad=20)
    ax.set_xlabel('月', fontsize=12)
    ax.set_ylabel('マッチング数', fontsize=12)
    ax.grid(True, alpha=0.3)
    
    # x軸のラベルを見やすく
    plt.xticks(rotation=45)
    
    # 保存パスを絶対パスで指定
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_path = os.path.join(script_dir, '..', '..', '..', 'app', 'assets', 'images', 'monthly_trend_chart.png')
    output_path = os.path.abspath(output_path)
    
    # publicディレクトリにもコピー
    public_path = os.path.join(script_dir, '..', '..', '..', 'public', 'monthly_trend_chart.png')
    public_path = os.path.abspath(public_path)
    
    # ディレクトリが存在しない場合は作成
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    os.makedirs(os.path.dirname(public_path), exist_ok=True)
    
    print(f"Saving trend chart to: {output_path}")
    plt.savefig(output_path, dpi=300, bbox_inches='tight', facecolor='white')
    
    print(f"Copying trend chart to: {public_path}")
    plt.savefig(public_path, dpi=300, bbox_inches='tight', facecolor='white')
    plt.close()
    
    return True

def main():
    """メイン処理"""
    print("マッチング統計グラフを生成中...")
    
    # 統計データ取得
    stats = get_match_statistics()
    if not stats:
        print("統計データの取得に失敗しました")
        sys.exit(1)
    
    # グラフ生成
    success1 = generate_match_rate_chart(stats)
    success2 = generate_monthly_trend_chart(stats)
    
    if success1 and success2:
        print("グラフの生成が完了しました")
        
        # 統計データをJSONで出力
        stats_json = {
            'total_users': stats['total_users'],
            'match_rate': round(stats['match_rate'], 1),
            'total_matches': stats['total_matches'],
            'success_rate': round(stats['success_rate'], 1),
            'generated_at': datetime.now().isoformat()
        }
        
        # JSONファイルの保存パスを絶対パスで指定
        script_dir = os.path.dirname(os.path.abspath(__file__))
        json_path = os.path.join(script_dir, '..', '..', '..', 'public', 'match_stats.json')
        json_path = os.path.abspath(json_path)
        
        # ディレクトリが存在しない場合は作成
        os.makedirs(os.path.dirname(json_path), exist_ok=True)
        
        print(f"Saving JSON to: {json_path}")
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(stats_json, f, ensure_ascii=False, indent=2)
        
        print(f"統計データ: {stats_json}")
        sys.exit(0)
    else:
        print("グラフの生成に失敗しました")
        sys.exit(1)

if __name__ == "__main__":
    main()

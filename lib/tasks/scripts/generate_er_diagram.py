#!/usr/bin/env python3
import matplotlib
matplotlib.use('Agg')  # GUIバックエンドを使わない設定
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch, Rectangle
import sys
import os
from datetime import datetime

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

# データベーススキーマの定義
ENTITIES = {
    'users': {
        'position': (1, 7),
        'fields': [
            'id (PK)',
            'name',
            'email (UNIQUE)',
            'encrypted_password',
            'skill',
            'description',
            'reset_password_token',
            'reset_password_sent_at',
            'remember_created_at',
            'created_at',
            'updated_at'
        ],
        'color': '#E3F2FD',
        'description': 'ユーザー情報'
    },
    'matches': {
        'position': (6, 7),
        'fields': [
            'id (PK)',
            'user_id (FK)',
            'target_user_id (FK)',
            'status',
            'created_at',
            'updated_at'
        ],
        'color': '#F3E5F5',
        'description': 'マッチング情報'
    },
    'chat_rooms': {
        'position': (11, 7),
        'fields': [
            'id (PK)',
            'match_id (FK)',
            'name',
            'created_at',
            'updated_at'
        ],
        'color': '#E8F5E8',
        'description': 'チャットルーム'
    },
    'messages': {
        'position': (11, 3),
        'fields': [
            'id (PK)',
            'chat_room_id (FK)',
            'user_id (FK)',
            'content',
            'read_at',
            'created_at',
            'updated_at'
        ],
        'color': '#FFF3E0',
        'description': 'メッセージ'
    },
    'deals': {
        'position': (6, 3),
        'fields': [
            'id (PK)',
            'match_id (FK)',
            'client_id (FK)',
            'freelancer_id (FK)',
            'title',
            'description',
            'status',
            'price',
            'deadline',
            'created_at',
            'updated_at'
        ],
        'color': '#FFEBEE',
        'description': '取引情報'
    }
}

# リレーションシップの定義
RELATIONSHIPS = [
    # Users -> Matches (1:many as user)
    {
        'from': 'users',
        'to': 'matches',
        'from_pos': 'right',
        'to_pos': 'left',
        'label': '1:N\n(送信者)',
        'type': 'one_to_many',
        'offset_y': 0.2
    },
    # Users -> Matches (1:many as target_user) - curved line
    {
        'from': 'users',
        'to': 'matches',
        'from_pos': 'right',
        'to_pos': 'left',
        'label': '1:N\n(受信者)',
        'type': 'one_to_many',
        'offset_y': -0.2,
        'curved': True
    },
    # Matches -> ChatRooms (1:1)
    {
        'from': 'matches',
        'to': 'chat_rooms',
        'from_pos': 'right',
        'to_pos': 'left',
        'label': '1:1',
        'type': 'one_to_one'
    },
    # Matches -> Deals (1:many)
    {
        'from': 'matches',
        'to': 'deals',
        'from_pos': 'bottom',
        'to_pos': 'top',
        'label': '1:N',
        'type': 'one_to_many'
    },
    # ChatRooms -> Messages (1:many)
    {
        'from': 'chat_rooms',
        'to': 'messages',
        'from_pos': 'bottom',
        'to_pos': 'top',
        'label': '1:N',
        'type': 'one_to_many'
    },
    # Users -> Messages (1:many) - curved line
    {
        'from': 'users',
        'to': 'messages',
        'from_pos': 'bottom',
        'to_pos': 'left',
        'label': '1:N\n(作成者)',
        'type': 'one_to_many',
        'curved': True
    },
    # Users -> Deals (1:many as client) - curved line
    {
        'from': 'users',
        'to': 'deals',
        'from_pos': 'bottom',
        'to_pos': 'left',
        'label': '1:N\n(クライアント)',
        'type': 'one_to_many',
        'curved': True,
        'offset_y': 0.3
    },
    # Users -> Deals (1:many as freelancer) - curved line
    {
        'from': 'users',
        'to': 'deals',
        'from_pos': 'bottom',
        'to_pos': 'left',
        'label': '1:N\n(フリーランサー)',
        'type': 'one_to_many',
        'curved': True,
        'offset_y': -0.3
    }
]

def get_entity_connection_point(entity_name, entity_data, position):
    """エンティティの接続点を取得"""
    x, y = entity_data['position']
    width = max(3.0, len(max(entity_data['fields'], key=len)) * 0.12)
    height = len(entity_data['fields']) * 0.25 + 0.6
    
    if position == 'left':
        return x, y + height/2
    elif position == 'right':
        return x + width, y + height/2
    elif position == 'top':
        return x + width/2, y + height
    elif position == 'bottom':
        return x + width/2, y
    else:
        return x + width/2, y + height/2

def draw_entity(ax, entity_name, entity_data):
    """エンティティ（テーブル）を描画"""
    x, y = entity_data['position']
    fields = entity_data['fields']
    color = entity_data['color']
    description = entity_data['description']
    
    # テーブルのサイズを計算
    max_field_length = max(len(field) for field in fields)
    width = max(3.0, max_field_length * 0.12)
    height = len(fields) * 0.25 + 0.6
    
    # テーブルの枠を描画
    table_box = FancyBboxPatch(
        (x, y), width, height,
        boxstyle="round,pad=0.03",
        facecolor=color,
        edgecolor='black',
        linewidth=1.5
    )
    ax.add_patch(table_box)
    
    # テーブル名を描画
    ax.text(x + width/2, y + height - 0.15, entity_name.upper(),
           ha='center', va='center', fontweight='bold', fontsize=12)
    
    # 説明を描画
    ax.text(x + width/2, y + height - 0.35, f'({description})',
           ha='center', va='center', fontsize=9, style='italic', color='#666')
    
    # 区切り線を描画
    ax.plot([x + 0.1, x + width - 0.1], [y + height - 0.5, y + height - 0.5], 
           'k-', linewidth=1)
    
    # フィールドを描画
    for i, field in enumerate(fields):
        field_y = y + height - 0.75 - (i * 0.25)
        # PKやFKを強調
        if '(PK)' in field:
            ax.text(x + 0.1, field_y, field, ha='left', va='center', 
                   fontsize=9, fontweight='bold', color='#D32F2F')
        elif '(FK)' in field:
            ax.text(x + 0.1, field_y, field, ha='left', va='center', 
                   fontsize=9, fontweight='bold', color='#1976D2')
        elif '(UNIQUE)' in field:
            ax.text(x + 0.1, field_y, field, ha='left', va='center', 
                   fontsize=9, fontweight='bold', color='#388E3C')
        else:
            ax.text(x + 0.1, field_y, field, ha='left', va='center', fontsize=9)
    
    return x, y, width, height

def draw_relationship(ax, relationship):
    """リレーションシップを描画"""
    from_entity = relationship['from']
    to_entity = relationship['to']
    
    if from_entity not in ENTITIES or to_entity not in ENTITIES:
        return
    
    # 接続点を取得
    from_x, from_y = get_entity_connection_point(from_entity, ENTITIES[from_entity], relationship['from_pos'])
    to_x, to_y = get_entity_connection_point(to_entity, ENTITIES[to_entity], relationship['to_pos'])
    
    # オフセットを適用
    if 'offset_y' in relationship:
        from_y += relationship['offset_y']
        to_y += relationship['offset_y']
    
    # 線のスタイルを設定
    if relationship['type'] == 'one_to_one':
        line_width = 2.5
        line_color = '#E91E63'
    else:
        line_width = 1.5
        line_color = '#666'
    
    # 線を描画
    if relationship.get('curved', False):
        # 曲線で接続
        mid_x = (from_x + to_x) / 2
        mid_y = max(from_y, to_y) + 1.0
        
        # ベジエ曲線風の描画
        import numpy as np
        t = np.linspace(0, 1, 50)
        curve_x = (1-t)**2 * from_x + 2*(1-t)*t * mid_x + t**2 * to_x
        curve_y = (1-t)**2 * from_y + 2*(1-t)*t * mid_y + t**2 * to_y
        
        ax.plot(curve_x, curve_y, linewidth=line_width, color=line_color)
        
        # ラベル位置
        label_x, label_y = mid_x, mid_y + 0.2
    else:
        # 直線または折れ線で接続
        if relationship['from_pos'] in ['left', 'right'] and relationship['to_pos'] in ['left', 'right']:
            # 水平接続
            ax.plot([from_x, to_x], [from_y, to_y], 
                   linewidth=line_width, color=line_color)
            label_x, label_y = (from_x + to_x) / 2, from_y + 0.3
        else:
            # 垂直または複合接続
            if relationship['from_pos'] == 'bottom' and relationship['to_pos'] == 'top':
                ax.plot([from_x, from_x, to_x, to_x], [from_y, (from_y + to_y) / 2, (from_y + to_y) / 2, to_y],
                       linewidth=line_width, color=line_color)
            else:
                ax.plot([from_x, to_x], [from_y, to_y], 
                       linewidth=line_width, color=line_color)
            label_x, label_y = (from_x + to_x) / 2, (from_y + to_y) / 2 + 0.2
    
    # リレーションシップのラベルを描画
    ax.text(label_x, label_y, relationship['label'], 
           ha='center', va='center', fontsize=8, fontweight='bold',
           bbox=dict(boxstyle="round,pad=0.2", facecolor='white', alpha=0.9, edgecolor='gray'))

def generate_er_diagram():
    """ER図を生成"""
    print("Rails Matching Application のER図を生成中...")
    
    # 図のサイズを設定
    fig, ax = plt.subplots(figsize=(16, 10))
    ax.set_xlim(-0.5, 15.5)
    ax.set_ylim(0, 10)
    ax.set_aspect('equal')
    ax.axis('off')
    
    # タイトルを追加
    ax.text(8, 9.5, 'Rails Matching Application', 
           ha='center', va='center', fontsize=18, fontweight='bold')
    ax.text(8, 9.1, 'Entity Relationship Diagram', 
           ha='center', va='center', fontsize=14, fontweight='bold', color='#666')
    
    # エンティティを描画
    for entity_name, entity_data in ENTITIES.items():
        draw_entity(ax, entity_name, entity_data)
    
    # リレーションシップを描画
    for relationship in RELATIONSHIPS:
        draw_relationship(ax, relationship)
    
    # 凡例を追加
    legend_elements = [
        patches.Patch(color='#D32F2F', label='主キー (PK)'),
        patches.Patch(color='#1976D2', label='外部キー (FK)'),
        patches.Patch(color='#388E3C', label='ユニーク制約'),
        patches.Patch(color='#E91E63', label='1:1 リレーション'),
        patches.Patch(color='#666', label='1:N リレーション')
    ]
    
    ax.legend(handles=legend_elements, loc='upper right', bbox_to_anchor=(0.98, 0.35),
             fontsize=9, title='凡例', title_fontsize=10)
    
    # アプリケーション概要を追加
    overview_text = """このER図は、スキルマッチングアプリケーションのデータベース構造を表示しています。
    
主要な機能:
• ユーザー登録・認証 (Devise)
• スキルベースマッチング
• チャット機能
• 取引管理システム
• ファイル添付 (Active Storage)"""
    
    ax.text(0.5, 1.5, overview_text, fontsize=9, va='top', ha='left',
           bbox=dict(boxstyle="round,pad=0.3", facecolor='#F5F5F5', alpha=0.8))
    
    # 生成日時を追加
    ax.text(15, 0.2, f'生成日時: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}',
           ha='right', va='bottom', fontsize=8, color='#666')
    
    # 保存パスを絶対パスで指定
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_path = os.path.join(script_dir, '..', '..', '..', 'app', 'assets', 'images', 'er_diagram.png')
    output_path = os.path.abspath(output_path)
    
    # publicディレクトリにもコピー
    public_path = os.path.join(script_dir, '..', '..', '..', 'public', 'er_diagram.png')
    public_path = os.path.abspath(public_path)
    
    # ディレクトリが存在しない場合は作成
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    os.makedirs(os.path.dirname(public_path), exist_ok=True)
    
    print(f"ER図を保存中: {output_path}")
    plt.savefig(output_path, dpi=300, bbox_inches='tight', facecolor='white')
    
    print(f"ER図をpublicディレクトリにコピー中: {public_path}")
    plt.savefig(public_path, dpi=300, bbox_inches='tight', facecolor='white')
    plt.close()
    
    return True

def main():
    """メイン処理"""
    print("=" * 60)
    print("Rails Matching Application ER図生成ツール")
    print("=" * 60)
    
    success = generate_er_diagram()
    
    if success:
        print("✅ ER図の生成が完了しました")
        print(f"📅 生成日時: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("📁 保存場所: app/assets/images/er_diagram.png")
        sys.exit(0)
    else:
        print("❌ ER図の生成に失敗しました")
        sys.exit(1)

if __name__ == "__main__":
    main()

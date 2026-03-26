import pytest, sys
sys.path.insert(0, 'scripts/telegram')
from create_fragment import parse_fragment_message, generate_fragment_id

class TestParseThought:
    def test_plain_thought(self):
        result = parse_fragment_message("真正的謙遜不是貶低自己，而是清空自我。")
        assert result['type'] == 'thought'
        assert result['content'] == "真正的謙遜不是貶低自己，而是清空自我。"
        assert 'source' not in result

    def test_thought_with_chinese_tags(self):
        result = parse_fragment_message("謙遜是美德 #道家 #哲學")
        assert result['tags'] == ['道家', '哲學']
        assert '道家' not in result['content']

    def test_thought_with_no_tags(self):
        result = parse_fragment_message("一個沒有標籤的想法")
        assert result['tags'] == []

class TestParseQuote:
    def test_quote_with_page(self):
        result = parse_fragment_message("📖 塔羅冥想 p.114\n這是引文內容。")
        assert result['type'] == 'quote'
        assert result['source'] == '塔羅冥想'
        assert result['page'] == '114'
        assert result['content'] == '這是引文內容。'

    def test_quote_without_page(self):
        result = parse_fragment_message("📖 道德經\n致虛極，守靜篤。")
        assert result['type'] == 'quote'
        assert result['source'] == '道德經'
        assert 'page' not in result

    def test_quote_with_chapter(self):
        result = parse_fragment_message("📖 道德經 第十六章\n致虛極，守靜篤。")
        assert result['type'] == 'quote'
        assert result['page'] == '第十六章'

    def test_quote_with_tags(self):
        result = parse_fragment_message("📖 塔羅冥想 p.201\n靈感不是靠意志獲得的。 #靈性")
        assert result['tags'] == ['靈性']
        assert '#靈性' not in result['content']

class TestGenerateId:
    def test_id_format(self):
        frag_id = generate_fragment_id()
        parts = frag_id.split('-')
        assert len(parts) == 4
        assert len(parts[0]) == 8   # YYYYMMDD
        assert len(parts[1]) == 6   # HHMMSS
        assert len(parts[2]) == 3   # milliseconds
        assert len(parts[3]) == 4   # random hex

    def test_ids_are_unique(self):
        ids = [generate_fragment_id() for _ in range(10)]
        assert len(set(ids)) == 10

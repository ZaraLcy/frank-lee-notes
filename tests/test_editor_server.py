import pytest, sys
sys.path.insert(0, 'scripts/editor')
import server as srv

def test_parse_front_matter_basic():
    raw = "---\ntitle: \"測試\"\nfragment_ids:\n  - abc\n---\n\nbody"
    fm, body = srv.parse_front_matter(raw)
    assert fm['title'] == '測試'
    assert fm['fragment_ids'] == ['abc']
    assert body.strip() == 'body'

def test_parse_front_matter_no_body():
    raw = "---\ntitle: \"空的\"\nfragment_ids: []\n---\n"
    fm, body = srv.parse_front_matter(raw)
    assert fm['fragment_ids'] == []
    assert body.strip() == ''

def test_serialize_front_matter_roundtrip():
    fm = {'title': '隱修與服務', 'fragment_ids': ['20260325-120754-001-ab12']}
    body = '脈絡串說明'
    raw = srv.serialize_front_matter(fm, body)
    fm2, body2 = srv.parse_front_matter(raw)
    assert fm2['title'] == fm['title']
    assert fm2['fragment_ids'] == fm['fragment_ids']
    assert body2.strip() == body

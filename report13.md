#第3回課題レポート課題2
##課題
OpenFlow1.3 版スイッチの動作を説明しよう。

スイッチ動作の各ステップについて、trema dump_flows の出力 (マルチプルテーブルの内容) を混じえながら動作を説明すること。

### 実行のしかた

以下のように `--openflow13` オプションが必要です。

``` shellsession
$ bundle exec trema run lib/learning_switch13.rb --openflow13 -c trema.conf
```
##解答
以下の設定ファイルのような構成で行った．

```
vswitch('lsw') {
  datapath_id 0xabc
}

vhost ('host1') {
  ip '192.168.0.1'
}

vhost ('host2') {
  ip '192.168.0.2'
}

link 'lsw', 'host1'
link 'lsw', 'host2'
```
以下の手順でスイッチ動作を確認した．

```
1.ホスト1からホスト2にパケットを送る
2.ホスト2からホスト1にパケットを送る
3.再度ホスト1からホスト2にパケットを送る
```
それぞれの手順ごとにフローテーブルを確認する．
###初期のフローテーブル
以下にフローテーブルを示した．実行結果を以下に示す．

```
$ ./bin/trema dump_flows lsw
cookie=0x0, duration=16.339s, table=0, n_packets=0, n_bytes=0, priority=2,dl_dst=01:00:00:00:00:00/ff:00:00:00:00:00 actions=drop
cookie=0x0, duration=16.301s, table=0, n_packets=0, n_bytes=0, priority=2,dl_dst=33:33:00:00:00:00/ff:ff:00:00:00:00 actions=drop
cookie=0x0, duration=16.301s, table=0, n_packets=0, n_bytes=0, priority=1 actions=goto_table:1
cookie=0x0, duration=16.301s, table=1, n_packets=0, n_bytes=0, priority=3,dl_dst=ff:ff:ff:ff:ff:ff actions=FLOOD
cookie=0x0, duration=16.301s, table=1, n_packets=0, n_bytes=0, priority=1 actions=CONTROLLER:65535
```
テーブル0とテーブル1が存在する．テーブル0はフィルタリングを
行う．プライオリティ2の2つのdropルールがあるが，2つともマルチキャストのパケットをdropするというルールが記述されている．そうでない場合は3つ目のルールに従い，テーブル1に遷移する．  
テーブル1では宛先MACアドレスがff:ff:ff:ff:ff:ffであった場合にフラッディングを行うルールがプライオリティ3で存在する．そうでない場合はパケットインを行う．このルールはプライオリティ1である．
###手順1
ホスト1からホスト2にパケットを送った時のフローテーブルを示す．

```
$ ./bin/trema send_packets --source host1 --dest host2
$ ./bin/trema dump_flows lsw
cookie=0x0, duration=24.413s, table=0, n_packets=0, n_bytes=0, priority=2,dl_dst=01:00:00:00:00:00/ff:00:00:00:00:00 actions=drop
cookie=0x0, duration=24.375s, table=0, n_packets=0, n_bytes=0, priority=2,dl_dst=33:33:00:00:00:00/ff:ff:00:00:00:00 actions=drop
cookie=0x0, duration=24.375s, table=0, n_packets=1, n_bytes=42, priority=1 actions=goto_table:1
cookie=0x0, duration=24.375s, table=1, n_packets=0, n_bytes=0, priority=3,dl_dst=ff:ff:ff:ff:ff:ff actions=FLOOD
cookie=0x0, duration=24.375s, table=1, n_packets=1, n_bytes=42, priority=1 actions=CONTROLLER:65535
```
このパケットはマルチキャストパケットでなく，フラッディング用でもない．この場合テーブル0からテーブル1に遷移し，パケットインが起こる．
実際，3つ目のルールと5つ目のルールのn\_packetsが1増えている．
また，コントローラにはホスト1の情報が保存される．
###手順2
ホスト2からホスト1にパケットを送った時のフローテーブルを示す．
実行結果を以下に示す．

```
$ ./bin/trema send_packets --source host2 --dest host1
$ ./bin/trema dump_flows lsw
cookie=0x0, duration=48.663s, table=0, n_packets=0, n_bytes=0, priority=2,dl_dst=01:00:00:00:00:00/ff:00:00:00:00:00 actions=drop
cookie=0x0, duration=48.625s, table=0, n_packets=0, n_bytes=0, priority=2,dl_dst=33:33:00:00:00:00/ff:ff:00:00:00:00 actions=drop
cookie=0x0, duration=48.625s, table=0, n_packets=2, n_bytes=84, priority=1 actions=goto_table:1
cookie=0x0, duration=48.625s, table=1, n_packets=0, n_bytes=0, priority=3,dl_dst=ff:ff:ff:ff:ff:ff actions=FLOOD
cookie=0x0, duration=17.695s, table=1, n_packets=0, n_bytes=0, idle_timeout=180, priority=2,in_port=2,dl_src=9a:86:02:b3:f1:f8,dl_dst=75:79:21:80:5f:2e actions=output:1
cookie=0x0, duration=48.625s, table=1, n_packets=2, n_bytes=84, priority=1 actions=CONTROLLER:65535

```
今回も同様にフローテーブルにルールがないためにパケットインが起こる．コントローラにはホスト2の情報が保存される．コントローラにはホスト1の情報が保存されているために，flow mod メッセージが送られ，ホスト1宛てのパケットはポート1に送るルールがテーブル1に追加されている．
###手順3
再度ホスト1からホスト2にパケットを送る．実行結果を以下に示す．

```
$ ./bin/trema send_packets --source host1 --dest host2
$ ./bin/trema dump_flows lsw
cookie=0x0, duration=60.727s, table=0, n_packets=0, n_bytes=0, priority=2,dl_dst=01:00:00:00:00:00/ff:00:00:00:00:00 actions=drop
cookie=0x0, duration=60.689s, table=0, n_packets=0, n_bytes=0, priority=2,dl_dst=33:33:00:00:00:00/ff:ff:00:00:00:00 actions=drop
cookie=0x0, duration=60.689s, table=0, n_packets=3, n_bytes=126, priority=1 actions=goto_table:1
cookie=0x0, duration=60.689s, table=1, n_packets=0, n_bytes=0, priority=3,dl_dst=ff:ff:ff:ff:ff:ff actions=FLOOD
cookie=0x0, duration=3.609s, table=1, n_packets=0, n_bytes=0, idle_timeout=180, priority=2,in_port=1,dl_src=75:79:21:80:5f:2e,dl_dst=9a:86:02:b3:f1:f8 actions=output:2
cookie=0x0, duration=29.759s, table=1, n_packets=0, n_bytes=0, idle_timeout=180, priority=2,in_port=2,dl_src=9a:86:02:b3:f1:f8,dl_dst=75:79:21:80:5f:2e actions=output:1
cookie=0x0, duration=60.689s, table=1, n_packets=3, n_bytes=126, priority=1 actions=CONTROLLER:65535
```
今回もフローテーブルにルールが存在しないのでパケットインが起こる．今回のパケットはホスト2宛てのパケットであるが，コントローラにはホスト2の情報があるためにflow modメッセージが送られ，ホスト2宛てのルールがテーブル1に追加されている．

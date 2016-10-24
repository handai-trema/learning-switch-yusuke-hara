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

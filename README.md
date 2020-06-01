# exchange.sh
First Product I've made since I've joined a company.
---
title: "中間課題"
tags: "Markdown"
---
# 外貨両替を行うシェルスクリプト

-   簡単なフロー
-   関数で動きを分割する
-   関数化
-   エラー処理

## 1. 簡単なフロー

スクリプトを起動

↓

基準となる通貨の入力（ベース通貨）⇔入力ミス

↓

変換したい相手国通貨の入力（ターゲット通貨）⇔入力ミス

↓

変換する金額をベースとする通貨の金額で入力⇔入力ミス

↓

[欧州中央銀行](https://www.ecb.europa.eu/home/html/index.en.html)が提供するAPIを使って外貨レートを取得

↓

計算

↓

結果を出力

##### 使用環境

-   CentOS8
-   vim-enhanced
-   `jq`と`curl`をインストール

### 上記のフローを達成するためのシェルスクリプトの構成を考える

必要な動きはどうなるだろうか？

-   通貨を入力する（ベースとターゲット）筐｡変数で保存
-   金額を入力する筐｡変数で保存
-   外貨レートの情報を取得する筐｡変数で保存
-   計算を行う筐｡変数で保存
-   結果を出力する

少なくとも以上の動きは必要になるか？

## 2. 関数で動きを分割する

必要な動きはだんだんわかってきたので、その動きをシェルスクリプトの形で作っていく中でそれらの調整をしやすいように各動きを分割したい。ということで今回はシェルスクリプトの関数の機能を使って分割していくことにした。

### 2-1. 通貨の種類を入力から受け取る

まず、外貨両替をする際には変換元と変換先の通貨を指定する必要がある。

今回は欧州中央銀行のAPIから得られる32通貨の中からユーザーが好きなものを選べる形にしたい。
というわけで、32通貨を要素に取る配列を作り、ユーザーは目的の通貨のインデックス番号を入力して指定するという動きを作っていく。

```bash
array_currency_code=("JPY" "KRW" "USD" "EUR" "AUD"  "CNY" "BGN" "CZK" "DKK" "GBP" "HUF" "PLN" "RON" "SEK" "CHF" "ISK" "NOK" "HRK" "RUB" "TRY" "BRL" "CAD" "HKD" "IDR" "INR" "MXN" "MYR" "NZD" "PHP" "SGD" "THB" "ZAR")

function numTocode(){
	local num=$(expr "$1" - 1) #インデックス番号は0から始まるため
    echo ${array_currency_code["$num"]} #array_countryは対応している通貨コードが入っている配列
}
```

関数内で`read`を使うことは考えたが、いろいろややこしくなったので入力された数字は引数の形で受け取ることにした。
使用するAPIが通貨コードで色々指定するので、それに使うために通貨コードを標準出力に指定している。

### 2-2. 金額を入力する

これは値を`read`で受け取り数字かどうかを確認するのみなので割愛

（数値判定は`expr`を用いた計算の終了値による整数判定をクリアする、`tr -d [:digit:]`で数字を削った後に小数点が一つ残る場合のみ認めるという形で行った。）

[数値を判断するShell関数 - A Memorandum](https://blog1.mammb.com/entry/20091025/1256460372)

### 2-3. 外貨レートの情報を取得する

外貨のレートは欧州中央銀行のWebAPIを用いて取得する。

WebAPIからはJSONファイルで返ってくるため、JSONファイルを扱うためのコマンド`jq`を用いる。

(Java Script Object Notation)

```json
{"rates":{"JPY":0.00102, "HKD":0,9309}} #etc...
```

`curl`コマンドを使ってAPIをたたき最新のレートを取得する。
`curl`は指定のURLをからファイルをダウンロードするコマンド。（適当にたたくとHTMLが返ってくる）

（URLの後に`/latest`を付けることで指定している。）

```bash
curl https://api.exchangeratesapi.io/latest
```

このAPIはさらに細かい設定をすることが可能！

URLの後に`/latest?base=`をつけて通貨コードを添えると指定した通貨を基準としたレートを返してくれる。

```bash
curl https://api.exchangeratesapi.io/latest?base=JPY
```

さらにここから`jq`コマンドを使って目的の通貨との変換レートを取得する。

```bash
#EURを基準としたレート表を取得するとき
curl htttps://api.exchangeratesapi.io/latest?base=JPY | jq ".rates.EUR"
```

~~自分はうまくできなかったが、恐らく`jq`コマンドを使わずとも一発で目的のレートまで取得できるはず~~

### 2-4. 計算をする

入力された金額と、APIを用いて得られたレートから外貨を計算する。
シェルの`expr`コマンドでは整数の計算しかできないので小数も含めた計算ができる`bc`コマンドを用いて計算を行う。
`echo "計算式" | bc `の形で計算結果を受け取ることができる。

```bash
function RateCalc(){
	local rate="$1"
    local amount="$2"
 #scale=12であることに特に理由はないです。
	echo "scale=12; ("$rate" * "$amount")" | bc 
    }
```

以上より入力した通貨の種類と金額から目的の通貨へと両替ができた。

## 3. 関数化

関数とは入力値に対して一定の処理を行い、値を返すもの。

```bash
function sample(){
	"処理"
    echo "戻り値"
    }
```

注意しなければならないのはbashにおいて`return`が他の言語と違う意味を持つこと。

(`return` は終了ステータスを返すもの。`$?`に格納される)

```bash
変数=$(関数　"$引数")

```

の形で変数に値を入れたい場合は`ehco`の標準出力の形で返す。

値を関数に入れる筐｡処理を行う筐｡値を変数に格納する筐｡また別の処理を行うときに変数の値を利用する。

### 3-1. 関数だけ別ファイルで作る

関数を用いる理由は

### - 見やすさ

正直、関数を全く使わずに処理を行うことも可能。~~だと思います~~

見やすさが与える影響

-   処理が見やすい
-   管理がしやすい
-   エラーを特定しやすい
    etc...

ただ、同じファイルに記述すると管理しづらいし見にくい。

なので別ファイルで作って、メインの処理ファイルで読み込めば......

「スクリプトフォルダ」－－－メインスクリプト
                        |   （呼び出す）
                        |　　　　↓
                      　　－関数ファイル

```bash
source 関数のファイル
read input
base=$(関数 "$input")
read input
target=$(関数　"$input")
rate=$(関数 "$base" "$target")
read amount
result=$(関数 "$rate" "$amount")
echo "$result"
```

多分、最小構成はこんな感じでは？？

### 3-2. 色を付けたい

bashシェルは見にくい！

インターフェースとして見やすいものが触りやすい。

というわけで`printf`コマンドで色を付ける。

```bash
# 赤文字の出力
printf "\033[31m%s\033[m" "文字列"
#\033がエスケープ文字
#[31m~[mで赤を指定
```

色のコードについてはWikipedia参照

[ANSI escape code - Wikipedia](https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters)

## 4. エラー処理

今回のシェルスクリプトで起こりうるエラーは？

-   入力ミス
-   APIの通信エラー
    致命的なのはAPI通信エラー。
    ヒューマンエラーは起こる。大事なのはそのあと。
    `select`と`case`で誤入力の場合は、再度入力するチャンスを与える。

```bash
select item in $menu
do
	case ${REPLY} in
    	"Pattern1" )
        		処理１ ;;
        "Pattern2" )
        		処理２ ;;
done
```

# 参考文献

[欧州中央銀行API(Foreign exchange rates API with currency conversion](https://exchangeratesapi.io/)
[bash コーディングルール](https://qiita.com/mato-599/items/053ca6e00fb747147e1c)

[jqコマンドでjsonから必要なデータのみを取得する](https://qiita.com/bunty/items/a769ebabbdd324ff0d6f)
[コマンドラインで少数の計算や比較をする方法 | LFI](https://linuxfan.info/post-1705)

[終了ステータス | UNIX & Linux コマンド・シェルスクリプト リファレンス](https://shellscript.sunone.me/exit_status.html)

[シェルスクリプト(sh/bash/zsh)で変数から変数へ代入する方法について](https://qiita.com/yuyuchu3333/items/850f530bc76505e5d412)

[シェルスクリプトの複数行コメントアウト - Qiita](https://qiita.com/tak4/items/377b45804c58a3438153)

[bashのヒアドキュメントを活用する](https://qiita.com/take4s5i/items/e207cee4fb04385a9952)

[配列を使用する | UNIX & Linux コマンド・シェルスクリプト リファレンス](https://shellscript.sunone.me/array.html)

[数値を判断するShell関数 - A Memorandum](https://blog1.mammb.com/entry/20091025/1256460372)

[BashのTips](http://kodama.fubuki.info/wiki/wiki.cgi/bash/tips?lang=jp#14)

[シェルスクリプトのechoで”問題なく”色をつける(bash他対応) - Qiita](https://qiita.com/ko1nksm/items/095bdb8f0eca6d327233#1677%E4%B8%87%E8%89%B224bit-%E3%82%AB%E3%83%A9%E3%83%BC)

[ANSI escape code - Wikipedia](https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters)

[8.4.25　printfコマンド（書式の引数を書式に従って変換し，標準出力に出力する） : JP1/Advanced Shell](http://itdoc.hitachi.co.jp/manuals/3021/30213B3210/0374.HTM)

[【bash】 echoとprintfの違い - どちらかというとごはん派](https://blog.goo.ne.jp/01_mai/e/fd8968994cd997594c368001fcf103e4)

[エラー監視時(set -e)の汎用トラップコード(trap) - Qiita](https://qiita.com/kobake@github/items/8d14f42ef5f36d4b80e4)

[bashでset -eやtrap使ってtry-catch＋throw処理をする方法 - YOMON8.NET](https://yomon.hatenablog.com/entry/2016/03/23/061647)

[bashのif文で正規表現を使用する方法: 小粋空間](http://www.koikikukan.com/archives/2019/07/01-235555.php)

[\[ bash \] 正規表現パターンマッチング - Qiita](https://qiita.com/penguin_dream/items/bf6efdd25c8b08e89939)

[シェルスクリプトに挑戦しよう（9）制御構文［その2］――caseによる条件分岐 (2/2)：“応用力”をつけるためのLinux再入門（29） - ＠IT](https://www.atmarkit.co.jp/ait/articles/1811/21/news009_2.html)

[bash 窶・if \[\]からの "\[：too many arguments"エラーの意味（角括弧）](https://www.it-swarm.dev/ja/bash/if-%E3%81%8B%E3%82%89%E3%81%AE-%EF%BC%9Atoo-many-arguments%E3%82%A8%E3%83%A9%E3%83%BC%E3%81%AE%E6%84%8F%E5%91%B3%EF%BC%88%E8%A7%92%E6%8B%AC%E5%BC%A7%EF%BC%89/1070004748/)

[while 文の使用方法 | UNIX & Linux コマンド・シェルスクリプト リファレンス](https://shellscript.sunone.me/while.html#%E4%B8%80%E8%88%AC%E7%9A%84%E3%81%AA%E4%BD%BF%E7%94%A8%E6%96%B9%E6%B3%95-3-%E7%84%A1%E9%99%90%E3%83%AB%E3%83%BC%E3%83%97)

[Linux - if文の条件式に関数を入れると引数が渡されない｜teratail](https://teratail.com/questions/69699)

[配色](https://tsutawarudesign.com/miyasuku5.html)

[【 bc 】コマンド――対話的に計算する、小数点以下の桁数を指定して計算する：Linux基本コマンドTips（121） - ＠IT](https://www.atmarkit.co.jp/ait/articles/1706/23/news018.html)

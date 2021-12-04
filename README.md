![Purview Machine Learning Lineage Solution Accelerator](./Deployment/img/PurviewMLLineageSolutionAccelerator.PNG)

## About this Repository 

Azure Purviewは、さまざまなソースのデータを管理・統制するための統合データガバナンスサービスです。

機械学習プロジェクトのライフサイクルには、生データを洞察力に変えるための多くのステップが含まれます。このプロセスでは通常、複数のチームで異なる役割やスキルを持つ個人が効果的にコラボレーションする必要があります。Azure Purviewは、MLエンティティとプロセスのエンドツーエンドのリネージを提供することで、この複雑なプロセスを簡素化し、コラボレーション、監査、デバッグの機能を向上させます。

このソリューションアクセラレータは、機械学習のシナリオに合わせてPurviewでエンドツーエンドのリネージを構築するために必要なリソースを開発者に提供します。

### 補足

#### 日本語版について

このリポジトリは、2021年11月時点の[Purview-Machine-Learning-Lineage-Solution-Accelerator](https://github.com/microsoft/Purview-Machine-Learning-Lineage-Solution-Accelerator/blob/main/README.md)の日本語訳し、環境構築を簡易化したものです。


##  クレジットリスク予測ML処理フロー
![Purview Machine Learning Lineage Introduction](./Deployment/img/PurviewMLLineageIntroduction.PNG)

## PurviewによるML処理のリネージ
![ML Lineage](./Deployment/img/MLLineageScreenshot.PNG)

## 前提条件
このソリューションアクセラレータを使用するには、以下が必要です。
- [Azureサブスクリプション](https://azure.microsoft.com/free/)へのアクセス
- docker
- VSCode Remote Container環境
- - [WSL 開発環境を設定するためのベスト プラクティス](https://docs.microsoft.com/ja-jp/windows/wsl/setup/environment) を参照して環境をセットアップしてください。「Docker を使用してリモート開発コンテナーを設定する」まで実行すればOKです。

必須ではありませんが、Azure Purview、Azure Synapse Analytics、Machine Learningについて事前に理解していると便利です。

その他のトレーニングやサポートについては、こちらをご覧ください。
1. [Azure Purview](https://azure.microsoft.com/ja-jp/services/purview/)
2. [Azure Synapse Analytics](https://azure.microsoft.com/ja-jp/services/synapse-analytics/) 
3. [Azure Machine Learning](https://azure.microsoft.com/ja-jp/services/machine-learning/) 

## 手順
手順の概要は以下の通りです。
- Azureリソースのセットアップ
- Purviewスキャンの実施
- Synapse SparkによるML処理の実行

注：Azure のコストを最小限に抑えるために、Purview インスタンスを積極的に使用する予定がない場合は、この演習の最後に削除することを検討してください。

### Step 1. Azureリソースのセットアップ

Azureリソースとして以下がデプロイされます。

- Azure Synapse Analytics
- Azure Data Lake Storage Gen2
- Azure Purview
- Azure Machine Learning
- Azure Key Vault (Azure ML用)
- Azure Blob Storage (Azure ML用)
- Application Insight (Azure ML用)

デプロイおよび設定はスクリプトで自動化されます。
デプロイ後、追加の設定として以下が実行されます。

- データのアップロード
- Purviewコレクションアクセス制御の設定
- Purviewデータソース、スキャンの登録
- Synapse Notebookのアップロード
- Synapse Spark Poolパッケージのアップロード

#### Step 1.1 ファイルのダウンロード

このリポジトリをクローンまたはダウンロードして、VSCodeでフォルダとして開きます。

#### Step 1.2 変数情報の設定

「.devcontainer」フォルダ内の 「envtemplate」を「devcontainer.env」に名前変更して、内容を更新します。

#### Step 1.3 Remote-Containerの起動およびdeply.shの実行

1. 「Ctrl + Shigt + P」より、「Open Folder in Conteiner」を選択して、コンテナを起動します。（[参考](https://github.com/Azure-Samples/modern-data-warehouse-dataops/blob/main/e2e_samples/parking_sensors/docs/devcontainer.md)）
2. ターミナルを起動して、以下を実行します。約10分で完了します。

```BASH

bash deploy.sh

```
3. 実行後、後ほど使う情報がフォルダ内にvariable.jsonとして出力されます。


### Step 2. Purviewスキャンの実施

アップロードされたサンプルデータをアセットとしてPurviewデータカタログに登録します。

#### Step 2.1 スキャンの実行

1. [Purivew Studio](https://web.purview.azure.com/resource/)に移動します。
2. このソリューションアクセラレータに使用する `Azure Active Directory` と `Account name` の名前を選択してください。
3. 「Data Map」 > 「Sources」> 「View Detail」を選択します。



4. 「Scans」 > 「Scan-adls2」 を選択します。



5. 「Run Scan Now」 > 「Full Scan」を選択して、スキャンを実行します。8分ほどでスキャンが完了し、カタログ検索が可能になります。

### Step 3. Synapse SparkによるML処理の実行

Synapse Sparkを利用してML処理を実行します。
Notebook内の変数に指定する情報は、Step 1.3で出力されたファイルを参照してください。

#### Step 3.1  

1. [Synapse Studio](https://web.azuresynapse.net/)にログインします。
2. このソリューションアクセラレータに使用する `Azure Active Directory` と `サブスクリプション` と `ワークスペース名` の名前を選択してください
3. Go to `開発`ハブに移動します。各ノートブックを開き、上部を`アタッチ先 > Spark2x4`に変更します。 

4. `01_Authenticate_to_Purview_AML.ipynb`で、2セル目の`<TENANT_ID>, <CLIENT_ID>, <CLIENT_SECRET>,<PURVIEW_NAME>`を更新します。

5. `01_Authenticate_to_Purview_AML.ipynb`で、3セル目の`<SUBSCRIPTION_ID>,<RESOURCE_GROUP>,<WORKSPACE_NAME>,<WORKSPACE_REGION>`を更新します。
6. `04_Create_CreditRisk_Experiment.ipynb`で、5セル目の`<Synapse Storage Account Name>`を更新します。
7. `すべて発行` をクリックしてノートブックの変更を発行します。
8. 以下のノートブックを最後まで実行します。
	- `04_Create_CreditRisk_Experiment.ipynb` (このノートブックは、インポートした他のノートブックを実行します)

*注意*
このノートブックにより、Azure Machine learningの推論エンドポイントとしてAzure Container Instanceがデプロイされます。
費用を停止する場合はAzure ML Studioから推論エンドポイントを削除してください

### Step 4. Purview Studio上でMachine Learning リネージの確認

1.  [Purview Studio](https://web.purview.azure.com/)を起動します。
2. `Browse Assets` > `By source type`を選択します。
3. `Custom Ml Model` > `creditrisk_model`を選択します。
4. `Lineage` を選択しリネージを確認します。
![ML Lineage](./Deployment/img/PurviewScreenshot.png)

### Step 5. アセットアップロードとAzure Machine Learning Noteboksでの実行 (オプション)
1. Azure Machine Learning studio [AML Studio](https://ml.azure.com/)を起動します。
2. このソリューションアクセラレータで使用する「サブスクリプション」と「ワークスペース」の名前を選択します。
3. AML Studioの「Notebooks」タブに移動し、「Data」フォルダを含む「AML Notebooks」フォルダにノートブックとスクリプトをアップロードします。
4. AML Studio の「Compute」タブを開き、「Compute Instances」をクリックします。
5. 新規をクリックして、新しいコンピュートインスタンスを作成します。
6. Jupyterをクリックして、コンピュートインスタンスを起動します。
7. 開いたブラウザウィンドウで、フォルダをクリックすると、ステップ`9.3`でアップロードしたノートブックが表示されます。
7. 7. `Authenticate_to_Purview_AML.py`で手順`2.1`のPurview Tenant, Client Id, Secretを更新します。
8. 認証_to_Purview_AML.py`のステップ`3.1`からAzure Machine Learning Tenant, Client Id, Secretを更新します。
9. 以下のノートブックを順番に実行します。
	- 01_Create_CreditRisk_AML_Pipeline.ipynb` ( パイプラインの実行には数分かかる場合がありますので、完了を待ってから次のノートブックを実行してください ) 
	- 02_Create_CreditRisk_AML_Pipeline_Lineage.ipynb `	

	
![ML Pipeline](./Deployment/img/AMLPipeline.PNG)	

### Step 6. Purview Studio上でMachine Learning Pipeline リネージの確認(オプション)
1. [Purview Studio](https://ms.web.purview.azure.com/)を起動します。
2. `Browse Assets` > `By source type`を選択します。
3.  `Custom ML Experiment Step`を選択します。
4. `Lineage` を選択しリネージを確認します。

![ML Pipeline Lineage](./Deployment/img/AMLPipelineLineage.PNG)
	
## Architecture
The architecture diagram below details what you will be building for this Solution Accelerator.
![Architecture](./Deployment/img/Architecture.PNG)


## License
MIT License

Copyright (c) Microsoft Corporation.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE

## Note about Libraries with MPL-2.0 and LGPL-2.1 Licenses   
The following libraries are not **explicitly included** in this repository, but users who use this Solution Accelerator may need to install them locally and in Azure Synapse and Azure Machine Learning to fully utilize this Solution Accelerator. However, the actual binaries and files associated with the libraries **are not included** as part of this repository, but they are available for installation via the PyPI library using the pip installation tool.  
  
Libraries: chardet, certifi

## Contributing
This project welcomes contributions and suggestions.  Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks
This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow [Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general). Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or logos are subject to those third-party's policies.

## Data Collection
The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft's privacy statement. Our privacy statement is located at https://go.microsoft.com/fwlink/?LinkID=824704. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.


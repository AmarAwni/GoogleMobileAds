import 'package:flutter/material.dart';
import 'package:google_ads/ads_manager.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late RewardedAd _rewardedAd;
  late InterstitialAd interstitialAd;
  int numInterstitialLoadAttempts = 0;
  bool isRewardedAdReady = false;
  var _balance = 0;

  //Banner Ad

  late BannerAd _bannerAd;
  bool _adIsLoaded = false;

  @override
  void initState() {
    _initGoogleMobileAds();
    _loadRewardedAd();
    loadInterstitialAd();
    //
    _bannerAd = BannerAd(
        adUnitId: AdsManager.bannerAdUnitId,
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            setState(() => _adIsLoaded = true);
          },
          onAdFailedToLoad: (ad, error) {
            setState(() => _adIsLoaded = false);
          },
        ));
    _bannerAd.load();
    //
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch more win more ..'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Center(
            child: Image.asset(
              'assets/images/coin.png',
              height: MediaQuery.of(context).size.width,
              width: MediaQuery.of(context).size.width,
            ),
          ),
          Center(
            child: Text(
              'Your balance is :',
              style: Theme.of(context).textTheme.headline4,
            ),
          ),
          Center(
            child: Text(
              '$_balance',
              style: Theme.of(context).textTheme.headline2,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                  onPressed: () {
                    _showRewardedAd();
                  },
                  child: const Text('Rewarded Ad')),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(primary: Colors.deepOrange),
                  onPressed: () {
                    showInterstitialAd();
                  },
                  child: const Text('Interstitial Ad')),
            ],
          ),
          _bannerAdWidget(),
        ],
      ),
    );
  }

  //Google mobile ads functions helper

  Future<InitializationStatus> _initGoogleMobileAds() {
    return MobileAds.instance.initialize();
  }

  static const int maxFailedLoadAttempts = 3;
  static const AdRequest request = AdRequest(
    keywords: <String>['game', 'tools', 'shopping'],
    contentUrl: 'https://www.codewithammar.com',
    nonPersonalizedAds: true,
  );

  void loadInterstitialAd() {
    InterstitialAd.load(
        adUnitId: AdsManager.interstitialAdUnitId,
        request: request,
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            interstitialAd = ad;
            numInterstitialLoadAttempts = 0;
            interstitialAd.setImmersiveMode(true);
          },
          onAdFailedToLoad: (LoadAdError error) {
            numInterstitialLoadAttempts += 1;

            if (numInterstitialLoadAttempts <= maxFailedLoadAttempts) {
              loadInterstitialAd();
            }
          },
        ));
  }

  void showInterstitialAd() {
    interstitialAd.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        print('ad onAdShowedFullScreenContent.');
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        ad.dispose();
        loadInterstitialAd();
      },
    );
    interstitialAd.show();
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AdsManager.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(onAdLoaded: (ad) {
        setState(() => _rewardedAd = ad);
        ad.fullScreenContentCallback =
            FullScreenContentCallback(onAdDismissedFullScreenContent: (ad) {
          setState(() => isRewardedAdReady = false);
          _loadRewardedAd();
        });
        setState(() => isRewardedAdReady = true);
      },
          //
          onAdFailedToLoad: (errer) {
        print('Failed to load $errer');
      }),
    );
  }

  //show Rewarded Ad
  void _showRewardedAd() {
    _rewardedAd.show(onUserEarnedReward: (RewardedAd ad, RewardItem item) {
      setState(() => _balance += item.amount.toInt());
    });
  }

  Widget _bannerAdWidget() {
    if (_adIsLoaded) {
      return Container(
        margin: const EdgeInsets.all(8),
        width: _bannerAd.size.width.toDouble(),
        height: _bannerAd.size.height.toDouble(),
        child: AdWidget(
          ad: _bannerAd,
        ),
      );
    } else {
      return Container();
    }
  }
}

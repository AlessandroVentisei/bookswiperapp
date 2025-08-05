class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.colorScheme.primary,
      appBar: AppBar(),
      body: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 160, 18, 78),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Read What You ',
                                  style: appTheme.textTheme.headlineLarge,
                                ),
                                TextSpan(
                                  text: 'Love',
                                  style: appTheme.textTheme.headlineLarge
                                      ?.copyWith(
                                    color: appTheme.colorScheme
                                        .secondary, // Change this to your desired color
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                              'Explore famous works of literature, from modern classics to ancient texts, with just a simple swipe.',
                              style: appTheme.textTheme.bodyLarge),
                        ],
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.arrow_forward),
                          iconAlignment: IconAlignment.end,
                          label: Text('Get started'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appTheme.colorScheme.secondary,
                            foregroundColor: appTheme.colorScheme.onSecondary,
                            textStyle: appTheme.textTheme.bodyMedium,
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, '/first');
                          },
                        ),
                      )
                    ],
                  ),
                )
              : HomePage();
        },
      ),
    );
  }
}
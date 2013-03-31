//
// IDZTwitterFollowersViewController.m
// IDZSocial/Twitter
//
// Copyright (c) 2013 iOSDeveloperZone.com
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
#import "IDZTwitterFollowersViewController.h"
#import <Accounts/Accounts.h>
#import <Social/Social.h>

#import "IDZAvatarDownloader.h"

@interface IDZTwitterFollowersViewController () {
    NSMutableArray *_objects;
    NSMutableDictionary* mImageCache;
    NSMutableDictionary* mDownloaders;
}
@end

@implementation IDZTwitterFollowersViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Followers", @"Followers");
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            self.clearsSelectionOnViewWillAppear = NO;
            self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    ACAccountStore* accountStore = [[ACAccountStore alloc] init];
    ACAccountType* accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    /*
     * It's not clear from Apple's documentation whether this call will succeed if access has not 
     * been granted.
     */
    NSArray* twitterAccounts = [accountStore accountsWithAccountType:accountType];
    if(twitterAccounts.count == 0)
    {
        NSLog(@"No accounts set up?.");
    }
    /*
     * On the simulator, if there are no twitter accounts set, this request will always return access denied.
     */
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError* error)
     {
         if(granted)
         {
             NSLog(@"Access granted. account=%@", accountStore);
             [self accessGranted:accountStore];
         }
         else
         {
             NSLog(@"Access denied. error=%@ localizedDescripton=%@", error, [error localizedDescription]);
         }
         
     }
     ];
}

- (void)accessGranted:(ACAccountStore *)accountStore
{
    ACAccountType* accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    NSArray* accounts = [accountStore accountsWithAccountType:accountType];
    NSLog(@"accounts=%@", accounts);
    if(accounts.count > 0)
    {
        //[self postStatusesUpdateForAccount:[accounts lastObject] status:@"Sammy De Beer is on twitter. (Test)."];
        ACAccount* account = [accounts lastObject];
        [self getFollowersListForAccount:account];
    }
    
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _objects.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        /*
         * Remember:
         *  UITableViewCellStyleDefault has image, but no subtitle.
         *  UITableViewCellStyleSubtitle
         */
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }


    NSDictionary *object = _objects[indexPath.row];
    cell.textLabel.text = [object objectForKey:@"name"];
    cell.detailTextLabel.text = @"detail";
    id profileImageURL = [object objectForKey:@"profile_image_url"];
    NSURL* url = [NSURL URLWithString:profileImageURL];
    
    cell.imageView.image = [mImageCache objectForKey:url];
    if(!cell.imageView.image && ![mDownloaders objectForKey:indexPath])
    {
        IDZAvatarDownloader* downloader = [[IDZAvatarDownloader alloc] initWithURL:url delegate:self context:indexPath];
        [downloader startDownload];
        [mDownloaders setObject:downloader forKey:indexPath];
    }
    else
    {
        NSLog(@"Cache hit");
    }
    
    NSLog(@"picture=%@ %@", [profileImageURL   class], profileImageURL);
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/



/**
 * https://dev.twitter.com/docs/api/1.1/get/followers/list
 */
- (void)getFollowersListForAccount:(ACAccount*)account
{
    NSURL* url = [NSURL URLWithString:@"https://api.twitter.com/1.1/followers/list.json"];
    SLRequest* getRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:url parameters:nil];
    getRequest.account = account;
    [getRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
     {
         [self followersListCompletedWithData:responseData response:urlResponse error:error];
     }
     ];
}

/**
 * @brief Callback for completed SLRequest
 *
 */
- (void)followersListCompletedWithData:(NSData*)data response:(NSHTTPURLResponse*)response error:(NSError*)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self mainFollowersListCompletedWithData:data response:response error:error];
    });

}

- (void)mainFollowersListCompletedWithData:(NSData*)data response:(NSHTTPURLResponse*)response error:(NSError*)error
{
    NSLog(@"urlResponse.statusCode=%d", response.statusCode);
    if(error)
    {
        NSLog(@"requestCompletedWithError = %@", error);
    }
    else
    {
//        NSString *dataAsString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSDictionary* jsonSerialization = [NSJSONSerialization
                                           JSONObjectWithData:data
                                           options:NSJSONReadingMutableLeaves
                                           error:&error];
        _objects = [jsonSerialization objectForKey:@"users"];
        [self.tableView reloadData];
    }
    
}

// MARK: -
- (void)downloader:(IDZAvatarDownloader*)downloader didDownloadAvatar:(UIImage*)avatar context:(id)context
{
    NSLog(@"Download complete for index path %@ url=%@", context, [downloader.response.URL absoluteString]);
    NSURL* url = downloader.response.URL;
    NSIndexPath* indexPath = (NSIndexPath*)context;
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.imageView.image = avatar;
    [cell layoutSubviews];
    [mImageCache setObject:avatar forKey:url];
    [mDownloaders removeObjectForKey:indexPath];
}
- (void)downloader:(IDZAvatarDownloader*)downloader didFailWithError:(NSError*)error context:(id)context
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}


@end

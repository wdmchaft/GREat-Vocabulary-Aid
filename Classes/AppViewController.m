    //
//  AppViewController.m
//  FlashCard
//
//  Created by Logan Moseley on 6/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AppViewController.h"
#import "CardViewController.h"


@implementation AppViewController

@synthesize delegate;
@synthesize frontsideViewController, backsideViewController;

#define kSwipeXDistance		60	// px
#define kSwipeYDistance		40	// px

#define kPrevCard			-1	// card selection from delegate
#define kCurrentCard		0	// same
#define kNextCard			1	// same

#define kFront				@"Front"	// card selection from delegate
#define kBack				@"Back"		// same

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	// Create and set the frontside view controller
	CardViewController *aController = [[CardViewController alloc] initWithNibName:@"FrontsideView" bundle:nil];
	aController.delegate = self;
	self.frontsideViewController = aController;
	[aController release];
	
	[self.view insertSubview:self.frontsideViewController.view atIndex:0];
}


# pragma mark Interface

- (IBAction)flipCard{
	
	// This flip animation settings //
	[UIView beginAnimations:@"View Flip" context:nil];
	[UIView setAnimationDuration:0.75];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	
	// self receives call-backs //
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationFinished:finished:context:)];
	self.view.userInteractionEnabled = FALSE;
	
	// Controllers of card views //
	CardViewController *coming;
	CardViewController *going;
	
	// If the front is currently visible
	if ([self isFrontShown]) {
		NSLog(@"Flipping to back");
		
		// Create and set the backside view controller
		CardViewController *bController = [[CardViewController alloc] initWithNibName:@"BacksideView" bundle:nil];
		bController.delegate = self;
		bController.textStr = [self getCurrentCard];
		self.backsideViewController = bController;
		[bController release];
		
		// Declare which controller to flip to/from
		coming = backsideViewController;
		going = frontsideViewController;
		
		// I will switch to back
	} 
	
	// If the back is currently visible
	else if (![self isFrontShown]) {
		NSLog(@"Flipping to front");
		
		// Create and set the frontside view controller
		CardViewController *fController = [[CardViewController alloc] initWithNibName:@"FrontsideView" bundle:nil];
		fController.delegate = self;
		fController.textStr = [self getCurrentCard];
		self.frontsideViewController = fController;
		[fController release];
		
		// Declare which controller to flip to/from
		coming = frontsideViewController;
		going = backsideViewController;
		
		// I will switch to front
	}
	
	// If we don't know what's going on
	else {
		NSLog(@"Neither front nor back are nil. I don't know what to do.");
		exit(0);
	}
	
	
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.view cache:YES];
	[coming viewWillAppear:YES];
	[going viewWillDisappear:YES];
	
	[going.view removeFromSuperview];
	[self.view insertSubview:coming.view atIndex:0];
	
	[going viewDidDisappear:YES];
	[coming viewDidAppear:YES];
	
	[UIView commitAnimations];
	
	
	// Make unseen card nil
	if ([self isFrontShown]) {
		backsideViewController = nil;
	} else {
		frontsideViewController = nil;
	}
}


- (void)animationFinished:(NSString *)animationID finished:(BOOL)finished context:(void *)context {
	self.view.userInteractionEnabled = TRUE;
	if ([self isFrontShown]) {
		[frontsideViewController replaceLabel:[self getCurrentCard]];
	} else {
		[backsideViewController replaceLabel:[self getCurrentCard]];
	}

}

- (BOOL)isFrontShown {
	if (self.frontsideViewController.view.superview != nil )
		return TRUE;
	else
		return FALSE;
}


#pragma mark Card Management

- (NSString*)getPrevCard {
	if ([self isFrontShown]) {
		return [delegate getCardText:kPrevCard forSide:kFront];
	} else {
		return [delegate getCardText:kPrevCard forSide:kBack];
	}
}

- (void)replaceWithPrevCard {
	[self replaceLabel:[self getPrevCard]];
}


- (NSString*)getCurrentCard {
	if ([self isFrontShown]) {
		return [delegate getCardText:kCurrentCard forSide:kFront];
	} else {
		return [delegate getCardText:kCurrentCard forSide:kBack];
	}
}

- (void)replaceWithCurrentCard {
	[self replaceLabel:[self getCurrentCard]];
}


- (NSString*)getNextCard {
	if ([self isFrontShown]) {
		return [delegate getCardText:kNextCard forSide:kFront];
	} else {
		return [delegate getCardText:kNextCard forSide:kBack];
	}
}

- (IBAction)replaceWithNextCard {
	[self replaceLabel:[self getNextCard]];
}

- (void)replaceLabel:(NSString *)newLabelText forSide:(NSString*)whichSide {
	if (whichSide == kFront) {
		[frontsideViewController replaceLabel:newLabelText];
	} else {
		[backsideViewController replaceLabel:newLabelText];
	}

}

- (void)replaceLabel:(NSString*)newLabelText {
	if ([self isFrontShown]) {
		[frontsideViewController replaceLabel:newLabelText];
	} else {
		[backsideViewController replaceLabel:newLabelText];
	}
}

- (IBAction)shuffleCards {
	[delegate shuffleCards];
//	NSLog(@"isFrontShown() is bool %d", [self isFrontShown]);
}



# pragma mark Touch Handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	touchBegan = [[touches anyObject] locationInView:self.view];	
//	NSLog(@"main | began | touchPoint: %@", NSStringFromCGPoint(touchBegan));
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {	
	CGPoint touchMoved = [[touches anyObject] locationInView:self.view];
//	NSLog(@"main | moved | touchPoint: %@", NSStringFromCGPoint(touchBegan));
	
	// Swipe > 30 left or right switches words
	if (abs(touchMoved.x-touchBegan.x) > kSwipeXDistance) {
		if (touchMoved.x-touchBegan.x > 0) {
			[self replaceWithNextCard];
		}
		else {
			[self replaceWithPrevCard];
		}
		
		touchBegan = touchMoved;
	}
	// Swipe > 20 up or down flips the card
	else if (abs(touchMoved.y-touchBegan.y) > kSwipeYDistance) {
		[self flipCard];
		touchBegan = CGPointMake(0, 0);
	}
}


#pragma mark Admin Stuff

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft
			|| interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[frontsideViewController release];
	[backsideViewController release];
    [super dealloc];
}


@end

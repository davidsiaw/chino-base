@import <Foundation/Foundation.j>
@import <OJUnit/OJTestCase.j>
@import <OJUnit/OJAssert.j>

@implementation SanityTest : OJTestCase

- (void)testThatTrueIsTrue
{
  [OJAssert assertTrue:YES];
}

- (void)testThatStringsAreEqual
{
  [OJAssert assert:"hello" equals:"hello"];
}

@end

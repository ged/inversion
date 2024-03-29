# Annotated Examples

This is a list of template examples with annotations explaining what each group of lines is doing.

## Simple Examples

...


## Advanced Examples

Here's a somewhat more complex example. At our company Spime-Thorpe from above, say we're creating a system that will handle mass layoffs without the need for management to handle all those messy personal interactions. We'll need a mass-mailer for the employees that will be afforded the chance to explore their career opportunities, right? So we create a template called `overboard-mail.tmpl`:

    <?config debugging_comments: true ?>
    <?default grace_period to "7 days" ?>
    
    <?begin?>
    <p>Dear <?call employee.fullname ?>,</p>
    <?rescue DatabaseError ?>
    <p>Dear Valued Ex-Employee,</p>
    <?end begin?>
    
    <p>Congratulations! You have been selected by <?call failed_company.name ?>'s
    elite management team as one of the many lucky individuals that will
    enjoy the exciting challenge of pursuing other rewarding employment
    opportunities!</p>
    
    <p><em>Kudos!</em></p>
    
    <p>You will find your accounts have been disabled, your desk has been helpfully 
    cleared out for you, and all of your personal effects packaged up and
    delivered to your address of record approximately 
    <?timedelta tracking_info.delivery_date ?>:</p>
    
    <?for line in employee.address ?>
    <?attr line ?><br />
    <?end for ?>
    
    <p>Please visit your <a href="[?call config.overboard_url ?]/[?uriencode 
    	failed_company.id ?]/[?uriencode employee.id ?]">customized Man OverBoard
    	transition site</a> immediately:</p>
    
    <p>This will acknowledge that you have received this message, and automatically 
    disable your email account.  Be sure and save this message!</p>
    
    <?if employee.severance_amount.nonzero? ?>
    <p>Failure to acknowledge this message within <?attr grace_period ?> could result 
    in delay of your final severance pay, in the amount of 
    <?call "$%0.2f" % employee.severance_amount ?>.</p>
    <?else?>
    <p>Failure to acknowledge this message within <?attr grace_period ?> will 
    result in automatic forfeiture of your numerous Man Overboard package benefits.</p>
    <?end if?>
    
    <?comment Disabled at client request ?>
    If you have any questions or concerns, please don't hesitate to contact your
    friendly Spime-Thorpe <a href="mailto:salesteam2@spime-thorpe.com">representative</a>.
    <?end comment ?>
    
    <p>Good Luck,<br />
    Your friends at Spime-Thorpe, Inc!<br />
    <a href="http://www.spime-thorpe.com/">http://www.spime-thorpe.com/</a></p>

When wrapped with a layout template, here's what this renders as:

    <?example { language: xml, caption: "The rendered output for one lucky individual" } ?>
    <!DOCTYPE html>
    <!--
    
    	Spime-Thorpe!
    	$Id$
    
      -->
    <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
    <head>
    	<title>Spime-Thorpe: Untitled</title>
    
    	<link rel="stylesheet" src="/css/base.css" type="text/css" />
    	
    	<script type="text/javascript" src="/js/jquery-latest.min.js"></script>
    	
    </head>
    <body>
    
    	<header>
    		<hgroup>
    			<h1>Spime-Thorpe</h1>
    			<h2></h2>
    		</hgroup>
    	</header>
    
    	<section id="content">
    <p>Dear James Random,</p>
    
    <p>Congratulations! You have been selected by Widgets R Us's
    elite management team as one of the many lucky individuals that will
    enjoy the exciting challenge of pursuing other rewarding employment
    opportunities!</p>
    
    <p><em>Kudos!</em></p>
    
    <p>You will find your accounts have been disabled, your desk has been helpfully 
    cleared out for you, and all of your personal effects packaged up and
    delivered to your address of record approximately 
    3 days ago:</p>
    
    1213 NE. Winding Road<br />
    Syracuse, NY  100213<br />
    
    <p>Please visit your <a href="http://failedcompany.spime-thorpe.com/overboard/a18661/1881">
    customized Man OverBoard transition site</a> immediately:</p>
    
    <p>This will acknowledge that you have received this message, and automatically 
    disable your email account.  Be sure and save this message!</p>
    
    <p>Failure to acknowledge this message within 11 days could result 
    in delay of your final severance pay, in the amount of 
    $12.81.</p>
    
    
    <p>Good Luck,<br />
    Your friends at Spime-Thorpe, Inc!<br />
    <a href="http://www.spime-thorpe.com/">http://www.spime-thorpe.com/</a></p>
    </section>
    
    	<footer>
    				<section id="copyright">Copyright 2011, Spime-Thorpe</section>
    	</footer>
    
    </body>
    </html>

This example can be found in the Inversion repository, in the `experiments` directory.


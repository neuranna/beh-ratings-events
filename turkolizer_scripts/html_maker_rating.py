# Edited in March 2020 by Yuan Bian
#   - update to Python 3
# Edited in May 2020 by Artyom Ivanov
#   - introduce the 1-7 scale
#   - adjust instructions
# Edited on 2020/05/26 by Anna Ivanova
#   - change instruction wording

import re
code = input("Enter code: ")
num_items = int(input("How many trials on the survey? "))
survey_name = input("What do you want to call the output file? ")
header = re.sub("<CODE>", code, """

<script type="text/javascript"> 

function stopRKey(evt) { 
  var evt = (evt) ? evt : ((event) ? event : null); 
  var node = (evt.target) ? evt.target : ((evt.srcElement) ? evt.srcElement : null); 
  if ((evt.keyCode == 13) && (node.type=="text"))  {return false;} 
} 

document.onkeypress = stopRKey; 

</script>

<h1>Sentence understanding</h1>

<p>&nbsp;</p>

<p><font color="red"><b>SURVEY CODE: <CODE> </b></font></p>


<p><font color="red"><i><b>PLEASE COMPLETE ONLY ONE&nbsp;</b><b>SURVEY WITH CODE </b><b><CODE></b><b>.&nbsp; YOU WILL NOT BE PAID FOR COMPLETING MORE THAN ONE SURVEY WITH THIS CODE.</b></i></font></p>

<p>&nbsp;</p>

<p>&nbsp;</p>

<p><b>Consent Statement</b><br />
<br />
By answering the following questions, you are participating in a study being performed by cognitive scientists in the MIT Department of Brain and Cognitive Science. If you have questions about this research, please contact Edward Gibson at egibson@mit.edu. Your participation in this research is voluntary. You may decline to answer any or all of the following questions. You may decline further participation, at any time, without adverse consequences. Your anonymity is assured; the researchers who have requested your participation will not receive any personal information about you.&nbsp;</p>

<p>Please answer the background questions below. The only restriction to being paid is achieving the accuracy requirements listed below. Payment is NOT dependent on your answers to the following background questions on country and language.</p>

<p>What country are you from? <input name="country" type="radio" value="USA" /><span class="answertext">USA </span>&nbsp;&nbsp;&nbsp; <input name="country" type="radio" value="CAN" /><span class="answertext">Canada</span>&nbsp; &nbsp; <input name="country" type="radio" value="UK" /><span class="answertext">UK &nbsp; &nbsp; </span><input name="country" type="radio" value="AUS" />Australia / New Zealand &nbsp;&nbsp;&nbsp;&nbsp;<input name="country" type="radio" value="IND" /><span class="answertext">India&nbsp; &nbsp; </span><input name="country" type="radio" value="OTHER" /><span class="answertext">Other&nbsp;&nbsp;</span></p>

<p>Is English your first language? <input name="English" type="radio" value="yes" /><span class="answertext"> Yes </span>&nbsp;&nbsp;&nbsp;<input name="English" type="radio" value="no" /><span class="answertext">No</span></p>

<h2>Instructions</h2>

<p><i>Please read each sentence and rate how plausible it is.
A completely plausible sentence describes a situation that commonly occurs in the real world and/or in books.
A completely implausible sentence describes a situation that never occurs in the real world and/or in books.</i></p>

<p><i>Do not spend too much time thinking about each sentence - just go with your intuition. </i></p>

<p><b>Please note that there are correct answers for some questions.</b></p>

<p>Because some Mechanical Turk users answer questions randomly, we will reject users with error rates of 25% or larger.<br />
<br />
---------------------------------------------------------------------------------------------------------------</p>""")

f = open(survey_name, "w")
f.write(header + "\n")

for i in range(1, num_items + 1):
    f.write("""<p id="${code__%(num)s}__%(num)s"><b>Sentence:</b> ${trial__%(num)s}</p>
<p><b>Sentence rating:</b></p>
<p>Completely implausible &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="radio" value="1" name="Rating__%(num)s" /><span class="answertext">1 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="radio" value="2" name="Rating__%(num)s"  /><span class="answertext"> 2 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="radio" value="3" name="Rating__%(num)s" /><span class="answertext"> 3 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="radio" value="4" name="Rating__%(num)s"  /><span class="answertext"> 4 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="radio" value="5" name="Rating__%(num)s"  /><span class="answertext"> 5 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="radio" value="6" name="Rating__%(num)s"  /><span class="answertext"> 6 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="radio" value="7" name="Rating__%(num)s"  /><span class="answertext"> 7 </span></span></span></span></span> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Completely plausible</p>
<p>---------------------------------------------------------------------------------------------------------------</p>""" %{"num":i})
    f.write("\n")

f.write("""<p>---------------------------------------------------------------------------------------------------------------</p>
<p><b><br />
</b>Thank you for your participation! Please leave any comments here.</p>
<p><textarea name="answer" cols="80" rows="3"></textarea></p>""")

f.close()

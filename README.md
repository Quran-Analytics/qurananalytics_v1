#Quran Analytics V1

This is the official repository consisting codes from the ![Quran Analytics Book](https://www.amazon.com/Quran-Analytics-R-Practical-Introduction/dp/B093SN84T4). This book was completed in 2021 and was slightly edited in 2024, mainly spellings, improvisation of graphs and code refactoring.

### Repository Structure

This book is written in bookdown. The order of the codes are as follow:

1.  index.Rmd
2.  01-Ch1Introduction.Rmd
3.  02-Part1.Rmd
4.  03-Ch2WordFrequency.Rmd
5.  04-Ch3WordScoring.Rmd
6.  05-Part2.Rmd
7.  06-Ch4WordLocCollCooc.Rmd
8.  07-Ch5WordLocStatAnal.Rmd
9.  08-Ch6WordLocNetAnal.Rmd
10.  09-Part3.Rmd
11.  10-Ch7TextNetAnal.Rmd
12.  11-Ch8TextClassModels.Rmd
13.  12-Ch9KnowledgeGraph.Rmd
14.  13-WayForward.Rmd

The files associated with bookdown output are as follow:
1.  _bookdown.yml
2.  _output.yml

The files associated with LaTex output / references are as follow:
1.  book.bib
2.  packages.bib
3.  preamble.tex
4.  qurananalytics.tex

The files associated with historical reference to the repository are as follow:
1.  sessioninfo.md
2.  changelog.md

Others:
1.  /data : Folder to store data
2.  /docs : Folder to hold output of bookdown
3.  /images
4.  aux/log/out/pdf : Files related to LaTex

### Run Code

To run the codes from the book, follow these instructions. These steps are assuming user have R and Rstudio installed on their device;

1.  Open QuranAnalytics.Rproj
2.  Check our Session Info (sessioninfo.md) to crosscheck user's package version with ours. Huge gaps between versions might cause an error.
3.  Open the desired topic via rMarkdown.
4.  Run.


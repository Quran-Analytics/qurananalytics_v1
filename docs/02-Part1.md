# Analysis of Words by its Frequencies {-}

> "What are the common patterns that occur in language use?” The major tool which we use to identify these patterns is counting things, otherwise known as statistics" [@manning1999, pg. 4]

The most basic element of text corpora is the word. Words form sentences. Sentences are organized as groups of words. A corpus consists of sentences assembled as paragraphs, sections, chapters as a set of documents. The elementary first step of Quran Analytics is to deal with the arrangement of words in the corpus. This is to reveal its basic structure, frequencies, in which part of the corpus the word appears, and any other observation of interest. This exercise is a generic statistical analysis in NLP.

Al-Quran consists of 77,430 words, 6,236 verses, and 114 Surahs - arranged in a specific order from the first word and verse to the last verse and word. The verses differ in length as well as the Surahs. Any translation of Al-Quran follows a similar structure, except for the words in each verse that may differ, based on the language and style of the authors.

Due to this unique arrangement, it is important to investigate the structures of the translations of Al-Quran (i.e., a corpus), in any language, sourced from the same original texts. These structures reveal the linguistic styles and the messages (or knowledge) transmission process of the texts.

This part consists of two chapters, Chapter 2 and Chapter 3. In Chapter 2 we will cover the statistical analysis of translations of Al-Quran. In Chapter 3 we choose one of the methods to deal with words by applying selected word scoring models, namely sentiment scoring. A full exercise for both tasks require lengthy expositions, which is not our intention. Instead, we provide a sketch of ideas of possible works as a guide for full-scale analysis.

We will utilize __R__ programming language, introduce some of the packages, and utilize some of the functions within these packages. We attach some of the codes wherever relevant and focus on visualizations of the results.

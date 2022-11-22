# I2S_transceiver
$$
\chapter{Εγχειρίδιο Χρήσης} %better title plz (Documentation)
\label{ch:chapter3}

Στο κεφάλαιο αυτό παρουσιάζονται τα χαρακτηριστικά της διεπαφής καθώς κ' οι απαραίτητες πληροφορίες για την ορθή χρήση της. Επιπλέον, αναλύεται η διαδικασία λειτουργίας που ακολουθείται, ανάλογα με την κατάσταση λειτουργίας στην οποία έχει ρυθμιστεί η διεπαφή.

% Η διεπαφή \tl{I2S} μπορεί να χρησιμοποιηθεί για την επικοινωνία με άλλες συσκευές που χρησιμοποιούν το πρωτόκολλο επικοινωνίας \tl{I2S}. Μπορεί να ρυθμιστεί ως κύριος ή υπηρέτης καθώς και ως πομπός ή παραλήπτης.

\section{Χαρακτηριστικά}

\begin{itemize}
\item Ο πομποδέκτης \tl{I2S} υποστηρίζει ημιαμφίδρομη επικοινωνία (λειτουργία πομπού ή παραλήπτη) και μπορεί να λειτουργήσει ως κύριος ή υπηρέτης.
    
\item Υποστηρίζεται η μετάδοση πλαισίων (\tl{frames}) μήκους 16 και 32 \tl{bit} για κάθε κανάλι τα οποία μπορούν να περιέχουν κωδικολέξεις μήκους 16, 24 και 32 \tl{bit}. Για να χρησιμοποιηθεί το πλαίσιο μήκους 16 \tl{bit} θα πρέπει η κωδικολέξη να έχει κι αυτή μήκος 16 \tl{bit}, σε άλλη περίπτωση χρησιμοποιείται αυτόματα πλαίσιο μήκους 32 \tl{bit}.

\item Υποστηρίζονται τα εξής \tl{I2S} πρωτόκολλα: πρότυπο \tl{Phillips I2S}, πρότυπο \tl{MSB Justified}, πρότυπο \tl{LSB Justified}.

\item Υποστηρίζονται δεδομένα στερεοφωνικού καθώς και μονοφωνικού ήχου.

\item Υπάρχει η δυνατότητα παύσης και σίγασης της μετάδοσης δεδομένων.

\item Υποστηρίζεται η προαιρετική έξοδος κύριου ρολογιού (\tl{master clock}) με συχνότητα 256 φορές μεγαλύτερη από τη συχνότητα δειγματοληψίας.% για την οδήγηση εξωτερικών δομικών στοιχείων ήχου. 

\item Υποστηρίζεται συχνότητα δειγματοληψίας 44.1 \tl{kHz} και 48 \tl{kHz}.

\item Το ρολόι του διαύλου \tl{I2S} παράγεται από το ρολόι του συστήματος χρησιμοποιώντας διαιρέτη συχνότητας. Υποστηρίζεται συχνότητα συστήματος 8, 16 και 32 \tl{MHz} αλλά δεν επιτρέπονται όλοι οι συνδυασμοί. Στον Πίνακα \ref{table:freqcomb} φαίνονται οι επιλογές που μπορούν να γίνουν ανάλογα με τη συχνότητα ρολογιού του συστήματος.

\item Διατίθενται 2 ενδιάμεσες μνήμες \tl{FIFO} χωρητικότητας 8 κωδικολέξεων μήκους 32 \tl{bit}, μία για αποστολή και μία για λήψη δεδομένων.

\item Διατίθενται 4 καταχωρητές για την επικοινωνία του λογισμικού με τη διεπαφή. Συγκεκριμένα, ο πρώτος περιέχει τις ρυθμίσεις της διεπαφής, ο δεύτερος τις σημαίες κατάστασης, ενώ οι υπόλοιποι δύο τα δεδομένα προς αποστολή και τα δεδομένα που έχουν παραληφθεί.
\end{itemize}

\begin{center} %table for pclk - sample_rate - mclk_en 
\begin{table}[h]
    \centering
    \begin{tabular}{|c|c|c|}
        \hline
        Ρολόι Συστήματος & Συχνότητα Δειγματοληψίας & Έξοδος Κύριου Ρολογιού \\
        \hline
        8 \tl{MHz} & 44.1 \tl{kHz} & ΟΧΙ \\
        \hline
        8 \tl{MHz} & 48 \tl{kHz} & ΟΧΙ \\
        \hline
        16 \tl{MHz} & 44.1 \tl{kHz} & ΟΧΙ \\
        \hline
        16 \tl{MHz} & 48 \tl{kHz} & ΟΧΙ \\
        \hline
        32 \tl{MHz} & 44.1 \tl{kHz} & ΟΧΙ \\
        \hline
        32 \tl{MHz} & 48 \tl{kHz} & ΟΧΙ \\
        \hline
        32 \tl{MHz} & 44.1 \tl{kHz} & ΝΑΙ \\
        \hline
        32 \tl{MHz} & 48 \tl{kHz} & ΝΑΙ \\
        \hline
    \end{tabular}
    \caption{Επιτρεπτοί Συνδυασμοί Συχνοτήτων.}
    \label{table:freqcomb}
\end{table}
\end{center}

\section{Καταχωρητές Διεπαφής}

Οι καταχωρητές της διεπαφής είναι προσβάσιμοι μέσω του διαύλου περιφερειακών συσκευών \tl{APB (Advanced Peripheral Bus)} \cite{APBspecs}. Παρακάτω παρουσιάζονται οι καταχωρητές της διεπαφής \tl{I2S} και περιγράφονται τα περιεχόμενα τους. 

\subsection{Καταχωρητής Ρυθμίσεων}
Ο καταχωρητής ρυθμίσεων (Πίνακας \ref{table:regctrl}) περιέχει όλα τα \tl{bit} ελέγχου της διεπαφής. Η επιλογή των ρυθμίσεων γίνεται από το λογισμικό πριν την έναρξη της μετάδοσης δεδομένων, σε άλλη περίπτωση επιλέγονται οι προεπιλεγμένες ρυθμίσεις. Για την ομαλή λειτουργία της διεπαφής, η επεγγραφή των ρυθμίσεων πρέπει να γίνεται όταν δεν πραγματοποιείται μετάδοση δεδομένων.

%Table:regctrl of register's contents
\begin{table}[H]
\begin{adjustwidth}{-1cm}{-1cm}
\begin{center}
\begin{tabular}{|cccclccccclccccc|}
\hline
\multicolumn{5}{|l|}{Όνομα Καταχωρητή} &
  \multicolumn{6}{l|}{Μετατόπιση Διέυθυνσης} &
  \multicolumn{5}{l|}{Προσβασιμότητα} \\ \hline 
\multicolumn{5}{|l|}{Καταχωρητής Ρυθμίσεων} &
  \multicolumn{6}{l|}{\tl{0x00}} &
  \multicolumn{5}{l|}{\tl{read \& write}} \\ \hline \hline
\multicolumn{1}{|c|}{\small{31:15}} &
  \small{14} &
  \multicolumn{1}{c|}{\small{13}} &
  \small{12} &
  \multicolumn{1}{c|}{\small{11}} &
  \multicolumn{1}{c|}{\small{10}} &
  \small{9} &
  \multicolumn{1}{c|}{\small{8}} &
  \multicolumn{1}{c|}{\small{7}} &
  \small{6} &
  \multicolumn{1}{c|}{\small{5}} &
  \multicolumn{1}{c|}{\small{4}} &
  \multicolumn{1}{c|}{\small{3}} &
  \multicolumn{1}{c|}{\small{2}} &
  \multicolumn{1}{c|}{\small{1}} &
  \small{0} \\ \hline
\multicolumn{1}{|c|}{\scriptsize{\tl{not used}}} &
  \multicolumn{2}{c|}{\textbf{\scriptsize{\tl{STND}}}} &
  \multicolumn{2}{c|}{\textbf{\scriptsize{\tl{MODE}}}} &
  \multicolumn{1}{c|}{\textbf{\scriptsize{\tl{SRATE}}}} &
  \multicolumn{2}{c|}{\textbf{\scriptsize{\tl{WRSZ}}}} &
  \multicolumn{1}{c|}{\textbf{\scriptsize{\tl{FRZS}}}} &
  \multicolumn{2}{c|}{\textbf{\scriptsize{\tl{SYSF}}}} &
  \multicolumn{1}{c|}{\textbf{\scriptsize{\tl{STER}}}} &
  \multicolumn{1}{c|}{\textbf{\scriptsize{\tl{MCKE}}}} &
  \multicolumn{1}{c|}{\textbf{\scriptsize{\tl{STOP}}}} &
  \multicolumn{1}{c|}{\textbf{\scriptsize{\tl{MUTE}}}} &
  \textbf{\scriptsize{\tl{RST}}} \\ \hline
\multicolumn{1}{|c|}{\scriptsize{\tl{reset values:}}} &
  \multicolumn{2}{c|}{\small{00}} &
  \multicolumn{2}{c|}{\small{11}} &
  \multicolumn{1}{c|}{\small{1}} &
  \multicolumn{2}{c|}{\small{10}} &
  \multicolumn{1}{c|}{\small{1}} &
  \multicolumn{2}{c|}{\small{10}} &
  \multicolumn{1}{c|}{\small{1}} &
  \multicolumn{1}{c|}{\small{0}} &
  \multicolumn{1}{c|}{\small{1}} &
  \multicolumn{1}{c|}{\small{0}} &
  \small{1} \\ \hline
\end{tabular}
\end{center}
\end{adjustwidth}
\caption{Περιγραφή καταχωρητή ρυθμίσεων.}
\label{table:regctrl}
\end{table}

\begin{description}
\item[\tl{STND}] \tl{Standard: Bits} επιλογής ενός από τα διαθέσιμα πρωτόκολλα ήχου.
    \n 00: πρότυπο \tl{I2S Philips}
    \n 01: πρότυπο \tl{MSB Justified}
    \n 10: πρότυπο \tl{LSB Justified}
\item[\tl{MODE}] \tl{Bits} επιλογής τρόπου λειτουργίας διεπαφής.
    \n 00: Υπηρέτης \& Παραλήπτης (\tl{Slave Receiver})
    \n 01: Υπηρέτης \& Πομπός (\tl{Slave Transmitter})
    \n 10: Κύριος \& Παραλήπτης (\tl{Master Receiver})
    \n 11: Κύριος \& Πομπός (\tl{Master Transmitter})
\item[\tl{SRATE}] \tl{Sample Rate: Bit} επιλογής συχνότητας δειγματοληψίας.
    \n 0: 44,1 \tl{kHz}
    \n 1: 48 \tl{kHz}
\item[\tl{WRSZ}] \tl{Word Size: Bits} επιλογής μεγέθους κωδικολέξης.
    \n 00: 16 \tl{bit}
    \n 01: 24 \tl{bit}
    \n 10: 32 \tl{bit}
\item[\tl{FRSZ}] \tl{Frame Size: Bit} επιλογής μεγέθους πλαισίου.
    \n 0: 16 \tl{bit}
    \n 1: 32 \tl{bit}
\item[\tl{SYSF}] \tl{System Frequency: Bits} επιλογής συχνότητας ρολογιού συστήματος.
    \n 00: 8 \tl{MHz}
    \n 01: 16 \tl{MHz}
    \n 10: 32 \tl{MHz}
\item[\tl{STER}] \tl{Stereo: Bit} επιλογής καναλιών.
    \n 0: μονοφωνικός ήχος (1 κανάλι)
    \n 1: στερεοφωνικός ήχος (2 κανάλια)
\item[\tl{MCKE}] \tl{Master Clock Enable: Bit} επιλογής εξόδου κύριου ρολογιού.
    \n 0: απενεργοποιημένη έξοδος
    \n 1: ενεργοποιημένη έξοδος 
\item[\tl{STOP}] \tl{Bit} επιλογής παύσης μετάδοσης.
    \n 0: απενεργοποιημένη επιλογή
    \n 1: ενεργοποιημένη επιλογή 
\item[\tl{MUTE}] \tl{Bit} επιλογής σίγασης μετάδοσης.
    \n 0: απενεργοποιημένη επιλογή
    \n 1: ενεργοποιημένη επιλογή 
\end{description}

\subsection{Καταχωρητής Σημαιών} %flags in greek??
Ο καταχωρητής σημαιών (Πίνακας \ref{table:regflags}) περιέχει σημαίες κατάστασης στις οποίες έχει πρόσβαση το λογισμικό ώστε να παρακολουθεί την κατάσταση στην οποία βρίσκεται η διεπαφή.

%Table:regflags of register's flags
\begin{table}[h]
\centering
\begin{tabular}{|lcccccc|lccc|lcc|}
\hline
\multicolumn{5}{|l|}{Όνομα Καταχωρητή}    & 
    \multicolumn{5}{l|}{Μετατόπιση Διεύθυνσης} &
    \multicolumn{4}{l|}{Προσβασιμότητα} \\ \hline
\multicolumn{5}{|l|}{Καταχωρητής Σημαιών} &
    \multicolumn{5}{l|}{\tl{0x04}} &
    \multicolumn{4}{l|}{\tl{read}} \\ \hline \hline
\multicolumn{1}{|c|}{31:13} &
  \multicolumn{1}{c|}{\small{12}} &
  \multicolumn{1}{c|}{\small{11}} &
  \multicolumn{1}{c|}{\small{10}} &
  \multicolumn{1}{c|}{\small{9}} &
  \multicolumn{1}{c|}{\small{8}} &
  \multicolumn{1}{c|}{\small{7}} &
  \multicolumn{1}{c|}{\small{6}} &
  \multicolumn{1}{c|}{\small{5}} &
  \multicolumn{1}{c|}{\small{4}} &
  \multicolumn{1}{c|}{\small{3}} &
  \multicolumn{1}{c|}{\small{2}} &
  \multicolumn{1}{c|}{\small{1}} &
  \multicolumn{1}{c|}{\small{0}} \\ \hline
\multicolumn{1}{|c|}{\scriptsize{\tl{not used}}} &
  \multicolumn{1}{c|}{\textbf{\scriptsize{\tl{TxRgE}}}} &
  \multicolumn{1}{c|}{\textbf{\scriptsize{\tl{RxRgF}}}} &
  \multicolumn{1}{c|}{\textbf{\scriptsize{\tl{IDL}}}} &
  \multicolumn{1}{c|}{\textbf{\scriptsize{\tl{TxCH}}}} &
  \multicolumn{1}{c|}{\textbf{\scriptsize{\tl{RxCH}}}} &
  \multicolumn{1}{c|}{\textbf{\scriptsize{\tl{TxF}}}} &
  \multicolumn{1}{c|}{\textbf{\scriptsize{\tl{TxE}}}} &
  \multicolumn{1}{c|}{\textbf{\scriptsize{\tl{TxAlF}}}} &
  \multicolumn{1}{c|}{\textbf{\scriptsize{\tl{TxAlE}}}} &
  \multicolumn{1}{c|}{\textbf{\scriptsize{\tl{RxF}}}} &
  \multicolumn{1}{c|}{\textbf{\scriptsize{\tl{RxE}}}} &
  \multicolumn{1}{c|}{\textbf{\scriptsize{\tl{RxAlF}}}} &
  \multicolumn{1}{c|}{\textbf{\scriptsize{\tl{RxAlE}}}} \\ \hline
\end{tabular}
\caption{Περιγραφή καταχωρητή σημαιών.}
\label{table:regflags}
\end{table}

\begin{description}
    \item[\tl{TxRgE}] \tl{Transmitter Data Register Empty:} Η σημαία άδειου καταχωρητή \textit{δεδομένων πομπού} σηκώνεται όταν ο καταχωρητής είναι κενός, έτσι ώστε το λογισμικό να προχωρήσει σε εισαγωγή δεδομένων. 
        \n 0: Πλήρης καταχωρητής
        \n 1: Κενός καταχωρητής
    \item[\tl{RxRgF}] \tl{Receiver Data Register Full:} Η σημαία πλήρους καταχωρητή \textit{δεδομένων παραλήπτη} σηκώνεται όταν ο καταχωρητής είναι πλήρης, έτσι ώστε το λογισμικό να προχωρήσει σε ανάγνωση δεδομένων. 
        \n 0: Κενός καταχωρητής
        \n 1: Πλήρης καταχωρητής
    \item[\tl{IDL}] \tl{Idle:} Η σημαία αδράνειας σηκώνεται αν την προκειμένη χρονική στιγμή δεν πραγματοποιείται μετάδοση δεδομένων.  
        \n 0: Μετάδοση δεδομένων σε εξέλιξη
        \n 1: Αναμονή δεδομένων
    \item[\tl{TxCH}] \tl{Transmitter Data Register Channel:} Η σημαία καναλιού του καταχωρητή \textit{δεδομένων πομπού} υποδεικνύει το κανάλι στο οποίο πρέπει να αντιστοιχούν τα δεδομένα που πρόκειται να εισαχθούν από το λογισμικό στον καταχωρητή. Στην περίπτωση μονοφωνικού ήχου υποδεικνύεται πάντα το αριστερό κανάλι.
        \n 0: Αριστερό κανάλι
        \n 1: Δεξιό Κανάλι
    \item[\tl{RxCH}] \tl{Receiver Data Register Channel:} Η σημαία καναλιού του καταχωρητή \textit{δεδομένων παραλήπτη} υποδεικνύει το κανάλι στο οποίο αντιστοιχούν τα δεδομένα που πρόκειται να λάβει το λογισμικό από τον καταχωρητή. Στην περίπτωση μονοφωνικού ήχου υποδεικνύεται πάντα το αριστερό κανάλι.
        \n 0: Αριστερό κανάλι
        \n 1: Δεξιό Κανάλι
    \item[\tl{TxF}] \tl{Transmitter FIFO Full:} Η σημαία πλήρους μνήμης πομπού σηκώνεται όταν είναι πλήρης η αντίστοιχη μνήμη \tl{FIFO}.  
        \n 0: Μη πλήρης μνήμη 
        \n 1: Πλήρης μνήμη
    \item[\tl{TxE}] \tl{Transmitter FIFO Empty:} Η σημαία κενής μνήμης πομπού σηκώνεται όταν είναι κενή η αντίστοιχη μνήμη \tl{FIFO}.  
        \n 0: Μη κενή μνήμη 
        \n 1: Κενή μνήμη
    \item[\tl{TxAlF}] \tl{Transmitter FIFO Almost Full:} Η σημαία σχεδόν πλήρους μνήμης πομπού σηκώνεται όταν η αντίστοιχη μνήμη \tl{FIFO} είναι σχεδόν πλήρης, συγκεκριμένα όταν υπάρχουν λιγότερες από 4 κενές θέσεις διαθέσιμες. 
        \n 0: Αρκετές θέσεις διαθέσιμες
        \n 1: Σχεδόν πλήρης μνήμη
    \item[\tl{TxAlE}] \tl{Transmitter FIFO Almost Empty:} Η σημαία σχεδόν κενής μνήμης πομπού σηκώνεται όταν είναι σχεδόν κενή η αντίστοιχη μνήμη \tl{FIFO}, συγκεκριμένα όταν υπάρχουν λιγότερες από 4 πλήρεις θέσεις διαθέσιμες. Έτσι το λογισμικό ενημερώνεται ότι πρέπει σύντομα να προχωρήσει σε εισαγωγή δεδομένων ώστε να μην αδειάσει η μνήμη και διακοπεί η ομαλή μετάδοση. 
        \n 0: Αρκετά δεδομένα διαθέσιμα
        \n 1: Σχεδόν κενή μνήμη
    \item[\tl{RxF}] \tl{Receiver FIFO Full:} Η σημαία πλήρους μνήμης παραλήπτη σηκώνεται όταν είναι πλήρης η αντίστοιχη μνήμη \tl{FIFO}.  
        \n 0: Μη πλήρης μνήμη 
        \n 1: Πλήρης μνήμη
    \item[\tl{RxE}] \tl{Receiver FIFO Empty:} Η σημαία κενής μνήμης παραλήπτη σηκώνεται όταν είναι κενή η αντίστοιχη μνήμη \tl{FIFO}.  
        \n 0: Μη κενή μνήμη 
        \n 1: Κενή μνήμη
    \item[\tl{RxAlF}] \tl{Receiver FIFO Almost Full:} Η σημαία σχεδόν πλήρους μνήμης παραλήπτη σηκώνεται όταν η αντίστοιχη μνήμη \tl{FIFO} είναι σχεδόν πλήρης, συγκεκριμένα όταν υπάρχουν λιγότερες από 4 κενές θέσεις διαθέσιμες. Έτσι το λογισμικό ενημερώνεται ότι πρέπει σύντομα να προχωρήσει σε ανάγνωση δεδομένων ώστε να μην γεμίσει η μνήμη και διακοπεί η ομαλή μετάδοση. 
        \n 0: Αρκετές θέσεις διαθέσιμες
        \n 1: Σχεδόν πλήρης μνήμη
    \item[\tl{RxAlE}] \tl{Receiver FIFO Almost Empty:} Η σημαία σχεδόν κενής μνήμης παραλήπτη σηκώνεται όταν είναι σχεδόν κενή η αντίστοιχη μνήμη \tl{FIFO}, συγκεκριμένα όταν υπάρχουν λιγότερες από 4 πλήρεις θέσεις διαθέσιμες.
        \n 0: Αρκετά δεδομένα διαθέσιμα
        \n 1: Σχεδόν κενή μνήμη
\end{description}

\subsection{Καταχωρητής Δεδομένων Πομπού}
Ο καταχωρητής δεδομένων του πομπού (Πίνακας \ref{table:regTxdata}) περιέχει τα δεδομένα που πρόκειται να αποσταλούν μέσω του διαύλου. Σε περίπτωση στερεοφωνικού ήχου οι κωδικολέξεις πρέπει να εισάγονται, από το λογισμικό, εναλλάξ για κάθε κανάλι, πρώτα το αριστερό κανάλι (κανάλι 1) και μετά το δεξιό κανάλι (κανάλι 2), όπως υποδεικνύεται από τη σημαία \tl{\textit{RxCH}}. Επιπλέον, η εισαγωγή δεδομένων γίνεται δεκτή μόνο όταν ο καταχωρητής είναι κενός, το οποίο υποδεικνύεται μέσω της σημαίας \tl{\textit{TxRgE}}. Τα δεδομένα πριν μεταδοθούν αποθηκεύονται προσωρινά στη μνήμη \tl{FIFO} του πομπού.

%Table:regTxdata of register's TxData
\begin{table}[H]
\centering
\begin{tabular}{|cll|}
\hline
\multicolumn{1}{|l|}{Όνομα Καταχωρητή} &
  \multicolumn{1}{l|}{Μετατόπιση Διεύθυνσης} &
  Προσβασιμότητα \\ \hline
\multicolumn{1}{|l|}{Καταχωρητής Δεδομένων Πομπού} &
  \multicolumn{1}{l|}{\tl{0x08}} &
  \tl{write} \\ \hline\hline
\multicolumn{3}{|c|}{31:0} \\ \hline
 \multicolumn{3}{|c|}{Δεδομένα προς αποστολή} \\ \hline
  \multicolumn{3}{|l|}{\tl{\small{reset value:}\hspace{4.8cm}0x0000}} \\ \hline
\end{tabular}
\caption{Περιγραφή καταχωρητή δεδομένων πομπού.}
\label{table:regTxdata}
\end{table}

\subsection{Καταχωρητής Δεδομένων Παραλήπτη}
Ο καταχωρητής δεδομένων του παραλήπτη (Πίνακας \ref{table:regRxdata}) περιέχει τα δεδομένα που έχουν παραληφθεί από τον δίαυλο. Σε περίπτωση στερεοφωνικού ήχου οι κωδικολέξεις πρέπει να ανακτηθούν, από το λογισμικό, εναλλάξ για κάθε κανάλι, πρώτα το αριστερό κανάλι (κανάλι 1) και μετά το δεξιό κανάλι (κανάλι 2), όπως υποδεικνύεται από τη σημαία \tl{\textit{RxCH}}. Επιπλέον, η ανάκτηση των δεδομένων γίνεται δεκτή μόνο όταν ο καταχωρητής είναι πλήρης, το οποίο υποδεικνύεται μέσω της σημαίας \tl{\textit{RxRgF}}. Τα δεδομένα αφού παραληφθούν, αποθηκεύονται προσωρινά στη μνήμη \tl{FIFO} του παραλήπτη.

%Table:regRxdata of register's RxData
\begin{table}[H]
\centering
\begin{tabular}{|cll|}
\hline
\multicolumn{1}{|l|}{Όνομα Καταχωρητή} &
  \multicolumn{1}{l|}{Μετατόπιση Διεύθυνσης} &
  Προσβασιμότητα \\ \hline
\multicolumn{1}{|l|}{Καταχωρητής Δεδομένων Παραλήπτη} &
  \multicolumn{1}{l|}{\tl{0x12}} &
  \tl{read} \\ \hline\hline
\multicolumn{3}{|c|}{31:0} \\ \hline
  \multicolumn{3}{|c|}{Δεδομένα που παραλήφθηκαν } \\ \hline
  \multicolumn{3}{|l|}{\tl{\small{reset value:}\hspace{4.8cm}0x0000}} \\ \hline
\end{tabular}
\caption{Περιγραφή καταχωρητή δεδομένων παραλήπτη.}
\label{table:regRxdata}
\end{table}

\section{Περιγραφή Λειτουργίας} %functional description

Η διεπαφή \tl{I2S}, πέρα από τους ακροδέκτες που συνδέονται με τον δίαυλο περιφερειακών, έχει 4 ακροδέκτες (Σχήμα \ref{fig:i2sTop}). Αυτοί αντιστοιχούν στη γραμμή μεταφοράς δεδομένων (\tl{SD}), στη γραμμή επιλογής καναλιού (\tl{WS}) και στο ρολόι (\tl{SCK} ή \tl{SCLK}) οι οποίες αποτελούν τον δίαυλο \tl{I2S,} σχεδιασμένο από την \tl{Philips} (βλ. Παράγραφο \ref{ch:i2s}). Επιπλέον υπάρχει ο ακροδέκτης του κύριου ρολογιού (\tl{MCK} ή \tl{MCLK}) για την έξοδο του αντίστοιχου σήματος όταν η συγκεκριμένη επιλογή είναι ενεργοποιημένη στον καταχωρητή ρυθμίσεων. 

\begin{figure}[H]
  \begin{center}
    \includegraphics[width=10cm]{PICS/I2S_top.png} 
    \caption{Οι ακροδέκτες της διεπαφής που συνδέονται με τον δίαυλο \tl{APB} (αριστερά) και τον δίαυλο \tl{I2S} (δεξιά).}
    \label{fig:i2sTop}
  \end{center}
\end{figure} %I2S top fig

Η αποστολή των δεδομένων γίνεται σε πλαίσια εξατομικευμένου μήκους και ξεκινάει αφού αλλάξει η κατάσταση του \tl{WS}, με το αριστερό κανάλι να προηγείται του δεξιού στην περίπτωση στερεοφωνικού ήχου. Η κατάσταση αυτή εξαρτάται από το πρωτόκολλο ήχου που επιλέχθηκε, σε κάθε περίπτωση η αποστολή των δεδομένων από τον πομπό γίνεται κατά την πτώση του \tl{SCLK} ενώ η λήψη τους από τον παραλήπτη κατά την άρση του \tl{SCLK}.   

\subsection{Συμβατά πρωτόκολλα ήχου}
\label{ch:sound_prot}
Για την αποστολή των δεδομένων δίνεται η επιλογή ενός από τα τρία διαθέσιμα πρότυπα ήχου (\tl{Phillips I2S, MSB \& LSB Justified}), το οποίο επιλέγεται μέσω των \tl{STND bits} στον καταχωρητή ρυθμίσεων. Στο πρότυπο \tl{I2S Philips} η αποστολή των δεδομένων ξεκινάει έναν κύκλο ρολογιού αφού "πέσει" το σήμα \tl{WS} από 1 σε 0. Στη συνέχεια, αποστέλλεται η κωδικολέξη με το \tl{MSB} πρώτο και στην περίπτωση που το μέγεθος του πλαισίου είναι μεγαλύτερο από αυτό της κωδικολέξης, τα \tl{bits} που περισσεύουν καθορίζονται κατ' ανάγκη 0 (Σχήμα \ref{fig:philstand}).

\begin{figure}[H]
  \begin{center}
    \includegraphics[width=14cm]{PICS/I2S_Phil_Standard.jpg} 
    \caption{Μετάδοση κωδικολέξης \tl{16-bit} σε πλαίσιο \tl{32-bit} χρησιμοποιώντας το πρότυπο \tl{Phillips I2S} \cite{STmanual}.}
    \label{fig:philstand}
  \end{center}
\end{figure} %Philips standard fig

Στα πρότυπα \tl{MSB \& LSB Justified} η αποστολή των δεδομένων ξεκινάει ταυτόχρονα με την άρση του σήματος \tl{WS} από 0 σε 1. Η μόνη διαφορά μεταξύ των δύο αυτών προτύπων παρατηρείται στην περίπτωση που το μέγεθος του πλαισίου είναι μεγαλύτερο από αυτό της κωδικολέξης. Στο \tl{MSB Justified} η κωδικολέξη καταλαμβάνει τα \tl{MSB} του πλαισίου (Σχήμα \ref{fig:MSBstand}) ενώ στο \tl{LSB Justified} καταλαμβάνει τα \tl{LSB} αντίστοιχα (Σχήμα \ref{fig:LSBstand}). Τα \tl{bits} που περισσεύουν καθορίζονται κατ' ανάγκη 0 όπως και στο πρότυπο \tl{I2S Philips}.

\begin{figure}[H]
  \begin{center}
    \includegraphics[width=14cm]{PICS/MSB_Standard.jpg} 
    \caption{Μετάδοση κωδικολέξης \tl{16-bit} σε πλαίσιο \tl{32-bit} χρησιμοποιώντας το πρότυπο \tl{MSB Justified} \cite{STmanual}.}
    \label{fig:MSBstand}
  \end{center}
\end{figure} %MSB standard fig
\begin{figure}[H]
  \begin{center}
    \includegraphics[width=14cm]{PICS/LSB_Standard.jpg} 
    \caption{Μετάδοση κωδικολέξης \tl{16-bit} σε πλαίσιο \tl{32-bit} χρησιμοποιώντας το πρότυπο \tl{LSB Justified} \cite{STmanual}.}
    \label{fig:LSBstand}
  \end{center}
\end{figure} %LSB standard fig

%end subsection

\subsection{Συχνότητα ρολογιού \tl{SCLK}}
\label{ch:sclk_freq}
Η συχνότητα που πρέπει να έχει το ρολόι του διαύλου \tl{I2S} είναι τέτοια ώστε η αναπαραγωγή του ήχου να είναι συνεχής χωρίς όμως την ανάγκη μεγάλων ενδιάμεσων μνημών. Εξαρτάται από τη συχνότητα δειγματοληψίας του σήματος, τα διαθέσιμα κανάλια ήχου και το μήκος του πλαισίου με το οποίο θα μεταδοθούν τα δεδομένα.

%math for: SCLK = Fs * Frame * Channels
\begin{equation}
    \label{eq:I2Sfreq}
    F_{I2S} = F_S * Fr * Ch,
\end{equation}

όπου
\begin{description}
    \item $F_{I2S}$: ο ρυθμός μετάδοσης δεδομένων του διαύλου (ή η συχνότητα ρολογιού \tl{SCLK} του διαύλου),
    \item $F_S$: η συχνότητα δειγματοληψίας,
    \item $Fr$: ο αριθμός των \tl{bits} που περιέχει ένα πλαίσιο,
    \item $Ch$: ο αριθμός των καναλιών προς μετάδοση.
\end{description}

Για παράδειγμα η αποστολή στερεοφωνικού ήχου, δειγματοληπτημένου στα 48 \tl{kHz} σε πλαίσιο μήκους 32 \tl{bit} απαιτεί ρυθμό μετάδοσης: $48 kHz * 32 bits * 2 = 3,072 Mbps$ δηλαδή συχνότητα ρολογιού $3,072 MHz$. Η παραπάνω συχνότητα προκύπτει από το κύριο ρολόι του συστήματος χρησιμοποιώντας έναν διαιρέτη συχνότητας, με μία απόκλιση της τάξης $\pm 5\%$. 


%end subsection

\subsection{Τρόποι Λειτουργίας Διεπαφής}
Η διεπαφή \tl{I2S} μπορεί να προγραμματιστεί σε λειτουργία κυρίου ή υπηρέτη ανεξάρτητα από τη λειτουργία της ως πομπός ή παραλήπτης. Αναλόγως την επιλογή ακολουθείται και διαφορετική διαδικασία λειτουργίας.  

\subsubsection{Κύριος}
Κατά τη λειτουργία κυρίου το ρολόι \tl{SCLK} και το σήμα επιλογής καναλιού \tl{WS} εξάγονται από τους αντίστοιχους ακροδέκτες. Το \tl{SCLK} παράγεται αφότου εισαχθούν οι επιθυμητές  ρυθμίσεις μέσω του καταχωρητή ρυθμίσεων και επιλεχθεί η λειτουργία κυρίου (\tl{MODE = '10' \tg{ή} '11'}). Το σήμα παράγεται μέσω του ρολογιού του συστήματος διαιρούμενο με τον κατάλληλο αριθμό, ώστε να προκύψει η επιθυμητή συχνότητα. Η συχνότητα του ρολογιού καθορίζεται από τις ρυθμίσεις που επιλέχθηκαν (βλ. παράγραφο \ref{ch:sclk_freq}) εάν και μόνο ο συνδυασμός τους είναι επιτρεπτός (βλ. πίνακα \ref{table:freqcomb}). Στην περίπτωση που είναι επιθυμητή η έξοδος του κύριου ρολογιού \tl{MCLK}, παράγεται αυτό αντί του \tl{SCLK}, μέσω του ρολογιού του συστήματος και στη συνέχεια υποδιαιρείται περαιτέρω για να παραχθεί το ρολόι \tl{SCLK}.

Για την έξοδο του σήματος \tl{WS} και την έναρξη της μετάδοσης δεδομένων πρέπει, αφότου εισαχθούν οι επιθυμητές  ρυθμίσεις στον πομπό όπως και στον παραλήπτη, να εισαχθούν τα δεδομένα προς αποστολή στον πομπό. Στη συνέχεια, με την απενεργοποίηση του \tl{bit} επιλογής \textit{\tl{STOP}} θα ξεκινήσει η μετάδοση των δεδομένων.

\subsubsection{Υπηρέτης}
Κατά τη λειτουργία υπηρέτη το σήμα ρολογιού \tl{SCLK} καθώς και το σήμα επιλογής καναλιού \tl{WS} εισάγονται από τον δίαυλο στους αντίστοιχους ακροδέκτες. Όπως και στη λειτουργία κυρίου, είναι συνετή η επιλογή κοινών ρυθμίσεων στον πομπό όπως και στον παραλήπτη καθώς και η εισαγωγή δεδομένων προς αποστολή στη μνήμη του πομπού πριν την έναρξη της μετάδοσης. Εφόσον, η διεπαφή έχει τεθεί σε λειτουργία υπηρέτη μέσω των αντίστοιχων \tl{bit} επιλογής (\tl{MODE = '00' \tg{ή} '01'}), αυτομάτως παρακολουθείται το σήμα \tl{WS} έτσι ώστε να ξεκινήσει η μετάδοση των δεδομένων αφότου παρατηρηθεί κάποια μεταβολή στο σήμα αυτό (το είδος της μεταβολής εξαρτάται από το πρωτόκολλο ήχου που έχει επιλεχθεί, βλ. παράγραφο \ref{ch:sound_prot}). 

\subsubsection{Πομπός}
Κατά τη λειτουργία πομπού τα δεδομένα προς αποστολή που εισάγονται από το λογισμικό στον καταχωρητή \textit{δεδομένων πομπού} της διεπαφή επεξεργάζονται, ανάλογα με τις ρυθμίσεις που έχουν επιλεχθεί, και αποθηκεύονται στην ενδιάμεση μνήμη στην επιθυμητή μορφή. Επομένως, είναι απαραίτητη η εισαγωγή των ρυθμίσεων προτού εισαχθούν τα δεδομένα. Επιπλέον, στην περίπτωση στερεοφωνικού ήχου είναι απαραίτητη η εισαγωγή της κωδικολέξης που αντιστοιχεί στο αριστερό κανάλι ενός ηχητικού δείγματος, προτού εισαχθεί η κωδικολέξη του δεξιού καναλιού αυτού του δείγματος.

Η εισαγωγή των δεδομένων στη διεπαφή πρέπει ιδανικά να συνεχιστεί κατά τη διάρκεια της μετάδοσης ώστε να μην αδειάσει ποτέ η ενδιάμεση μνήμη (χωρητικότητας 8 κωδικολέξεων). Στην περίπτωση που αδειάσει, εάν ο πομπός λειτουργεί ως κύριος του συστήματος, το σήμα επιλογής καναλιού και κατά συνέπεια οι υπηρέτες που είναι συνδεδεμένοι με αυτόν, θα τεθούν σε λειτουργία αναμονής και δεν θα λάβουν δεδομένα έως ότου εισαχθούν εκ νέου κωδικολέξεις στον πομπό. Αντίθετα, εάν ο πομπός λειτουργεί ως υπηρέτης και αδειάσει η ενδιάμεση μνήμη, επαναλαμβάνεται η αποστολή της τελευταίας κωδικολέξης έως ότου εισαχθεί κάποια νέα.

\subsubsection{Παραλήπτης}
Κατά τη λειτουργία παραλήπτη, μόλις ολοκληρωθεί η λήψη μιας ολόκληρης κωδικολέξης, αυτή μεταφέρεται στον καταχωρητή \textit{δεδομένων παραλήπτη}, αφότου γίνει η κατάλληλη επεξεργασία ώστε τα δεδομένα να επαναφερθούν στην αρχική τους μορφή. Όπως και στη λειτουργία πομπού, είναι αναγκαία η εισαγωγή των ρυθμίσεων προτού ξεκινήσει η μετάδοση δεδομένων. Επίσης, είναι συνετή η επιλογή κοινών ρυθμίσεων στον πομπό και τον παραλήπτη, χωρίς αυτό να είναι αναγκαίο. Η λήψη και η επεξεργασία των δεδομένων γίνεται πάντα με βάση τις ρυθμίσεις που εισάγονται στον παραλήπτη. 

Τα δεδομένα πρέπει ιδανικά να λαμβάνονται από το λογισμικό μέσω του καταχωρητή \textit{δεδομένων παραλήπτη} ανά τακτά χρονικά διαστήματα έτσι ώστε να μην γεμίσει ποτέ η ενδιάμεση μνήμη (χωρητικότητας 8 κωδικολέξεων). Στην περίπτωση που γεμίσει, εάν ο παραλήπτης λειτουργεί ως κύριος του συστήματος, το σήμα επιλογής καναλιού και κατά συνέπεια οι υπηρέτες που είναι συνδεδεμένοι με αυτόν, θα τεθούν σε λειτουργία αναμονής και δεν θα αποστέλλουν δεδομένα έως ότου ληφθεί από το λογισμικό τουλάχιστον μία κωδικολέξη. Αντίθετα, εάν ο παραλήπτης λειτουργεί ως υπηρέτης και γεμίσει η ενδιάμεση μνήμη, τα δεδομένα που λαμβάνει αγνοούνται.
$$

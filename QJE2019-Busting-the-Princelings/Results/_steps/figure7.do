*Figure 7*
use "$DATA/figure7.dta", replace

twoway (area gap no, color(gray) lcolor(white))(line princeling_price near_price no, lcolor(gray black)), ///
   xlabel(1 "20131001" 11 "20131011" 21 "20131021" 31 "20131031" 41 "20131110" 51 "20131120" 61 "20131130" ///
   71 "20131210" 81 "20131220" 91 "20131230" 101 "20140109" 111 "20140119" 121 "20140129"  ///
   , angle(45)) xtitle("Date") ylabel(-2000(1000)3000, angle(horizontal)) ///
   ytitle("Average Land Price") graphregion(color(white))  xline(62, lcol(black)) ///
   legend(cols(2) label(1 "Price Gap") label(2 "Princelings") label(3 "Non-Princelings (Matched Sample, 500m Radius)")) ///
   title("Panel A: Average Land Prices/Gap", color(black))
graph save Graph "$FIG/figure7a.gph", replace

twoway (area near_area princeling_area no, color(gray black) lcolor(white black)), ///
   xlabel(1 "20131001" 11 "20131011" 21 "20131021" 31 "20131031" 41 "20131110" 51 "20131120" 61 "20131130" ///
   71 "20131210" 81 "20131220" 91 "20131230" 101 "20140109" 111 "20140119" 121 "20140129"  ///
   , angle(45)) xtitle("Date") ylabel(0(2)6, angle(horizontal)) ///
   ytitle("Average Quantity of Land Purchased") graphregion(color(white))  xline(62, lcol(black)) ///
   legend(cols(1) label(1 "Non-Princelings (Matched Sample, 500m Radius)") label(2 "Princelings")) ///
   title("Panel B: Quantity of Land Purchased", color(black))
graph save Graph "$FIG/figure7b.gph", replace

graph combine "$FIG/figure7a.gph" "$FIG/figure7b.gph", row(2) graphregion(color(white)) ysize(8)
graph save Graph "$FIG/figure7.gph", replace



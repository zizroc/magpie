*** |  (C) 2008-2023 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of MAgPIE and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  MAgPIE License Exception, version 1.0 (see LICENSE file).
*** |  Contact: magpie@pik-potsdam.de

*' @code
*' First, all 2nd generation bioenergy area is fixed to zero, irrespective of type and
*' rainfed/irrigation.
vm_area.fx(j,kbe30,w)=0;
*' Second, the bounds for 2nd generation bioenergy area are released depending on
*' the dynamic sets bioen_type_30 and bioen_water_30.
*' SSP2 default settings are used for the historic period.
if(m_year(t) <= sm_fix_SSP2,
  vm_area.up(j,kbe30,"rainfed") = Inf;
else
  vm_area.up(j,bioen_type_30,bioen_water_30) = Inf;
);

*' @stop

*' No penalties or fallows exist in this realization
vm_rotation_penalty.fx(i)=0;
vm_fallow.fx(j)=0;

crpmax30(crp30) = yes$(f30_rotation_max_shr(crp30) < 1);
crpmin30(crp30) = yes$(f30_rotation_min_shr(crp30) > 0);

*' @code
*' Minimum semi-natural vegetation (SNV) share is fading in after 2020
p30_snv_shr(t,j) = p30_snv_scenario_fader(t) *
  (s30_snv_shr * sum(cell(i,j), p30_country_snv_weight(i))
  + s30_snv_shr_noselect * sum(cell(i,j), 1-p30_country_snv_weight(i)));

*' Cropland relocation in response to SNV policy is based on exogeneous land
*' cover information from the Copernicus Global Land Service (@buchhorn_copernicus_2020).
*' The rate of the policy implementation is derived based
*' on the difference of scenario fader values in consecutive time steps
p30_snv_relocation(t,j) = (p30_snv_scenario_fader(t) - p30_snv_scenario_fader(t-1)) *
  (i30_snv_relocation_target(j) * sum(cell(i,j), p30_country_snv_weight(i))
  + s30_snv_shr_noselect * sum(cell(i,j), 1-p30_country_snv_weight(i)));
*' The following lines take care of mismatches in the input
*' data (derived from satellite imagery from the Copernicus
*' Global Land Service (@buchhorn_copernicus_2020)) and in
*' cases of cropland reduction
p30_max_snv_relocation(t,j) = p30_snv_shr(t,j) * (p30_snv_scenario_fader(t) - p30_snv_scenario_fader(t-1)) * pcm_land(j,"crop");
p30_snv_relocation(t,j)$(p30_snv_relocation(t, j) > p30_max_snv_relocation(t,j)) = p30_max_snv_relocation(t,j);

*' Area potentially available for cropping
p30_avl_cropland(t,j) = f30_avl_cropland(j,"%c30_marginal_land%") * (1 - p30_snv_shr(t,j));
*' @stop

* Growth of trees on cropland is modelled by shifting age-classes according to time step length.
s30_shift = m_timestep_length_forestry/5;
* example: ac10 in t = ac5 (ac10-1) in t-1 for a 5 yr time step (s30_shift = 1)
    p30_treecover(t,j,ac)$(ord(ac) > s30_shift) = pc30_treecover(j,ac-s30_shift);
* account for cases at the end of the age class set (s30_shift > 1) which are not shifted by the above calculation
    p30_treecover(t,j,"acx") = p30_treecover(t,j,"acx")
                  + sum(ac$(ord(ac) > card(ac)-s30_shift), pc30_treecover(j,ac));

pc30_treecover(j,ac) = p30_treecover(t,j,ac);
v30_treecover.l(j,ac) = p30_treecover(t,j,ac);

p30_treecover_shr(t,j) = p30_treecover_scenario_fader(t) *
  (s30_treecover_shr * sum(cell(i,j), p30_country_snv_weight(i))
  + s30_treecover_shr_noselect * sum(cell(i,j), 1-p30_country_snv_weight(i)));

*define ac_est and ac_sub
ac_est(ac) = no;
ac_est(ac) = yes$(ord(ac) <= (m_yeardiff_forestry(t)/5));

ac_sub(ac) = no;
ac_sub(ac) = yes$(ord(ac) > (m_yeardiff_forestry(t)/5));

* fix before s30_treecover_scenario_start to pc30_treecover(j,ac)?
if(m_year(t) <= s30_treecover_scenario_start,
 v30_treecover.fx(j,ac) = pc30_treecover(j,ac);
else
 v30_treecover.lo(j,ac_est) = 0;
 v30_treecover.up(j,ac_est) = Inf;
 if(s30_treecover_decrease = 1,
  v30_treecover.lo(j,ac_sub) = 0;
  v30_treecover.up(j,ac_sub) = pc30_treecover(j,ac_sub);
 else
  v30_treecover.fx(j,ac_sub) = pc30_treecover(j,ac_sub);  
 );
);

p30_betr_shr(t,j) = p30_betr_scenario_fader(t) *
  (s30_betr_shr * sum(cell(i,j), p30_country_snv_weight(i))
  + s30_betr_shr_noselect * sum(cell(i,j), 1-p30_country_snv_weight(i)));

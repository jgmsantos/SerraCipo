load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/acentos.ncl"

begin

mes   = (/"Julho","Agosto","Setembro","Outubro"/)
nome_arquivos = (/"ACUM.MENSAL.PREC.IMERG.20200701.20201031.nc","MED.MENSAL.RH2M.GFS.ANL.20200701.20201031.nc","MED.MENSAL.TEMP2M.GFS.ANL.20200701.20201031.nc"/)
nome_variaveis = (/"prec","RH2m","TEMP2m"/)
nome_figura = (/"prec","umidade_relativa","temperatura"/)

do j = 0,dimsizes(nome_arquivos)-1

   print(""+nome_variaveis(j))

   if (nome_variaveis(j) .eq. "prec") then
       intervalo_valores := (/1,25,50,75,100,125,150/)
       cores := (/0,2,3,7,8,9,10,11/)
       unidade := "(mm m"+ecirc+"s~S~-1~N~)"
   end if 

   if (nome_variaveis(j) .eq. "RH2m") then
       intervalo_valores := (/50,52,54,56,58/)
       cores := (/2,3,7,8,9,10/)
       unidade := "(%)"
   end if 

   if (nome_variaveis(j) .eq. "TEMP2m") then
       intervalo_valores := (/22,24,26,28,30/)
       cores := (/2,3,7,8,9,10/)
       unidade := "(~S~o~N~C)"
   end if 

   f = addfile("../output/"+nome_arquivos(j),"r")

   var := f->$nome_variaveis(j)$

   wks = gsn_open_wks("png","../figuras/"+nome_figura(j))

   gsn_define_colormap(wks,"circular_1")

   plot = new(dimsizes(mes),graphic) 

   res                       = True
   res@gsnDraw               = False
   res@gsnFrame              = False
   res@cnInfoLabelOn         = False
   res@cnFillOn              = True
   res@lbLabelBarOn          = False
   res@gsnLeftString         = ""
   res@gsnRightString        = ""
   res@mpMinLonF             := -43.70
   res@mpMaxLonF             := -43.37
   res@mpMinLatF             := -19.59
   res@mpMaxLatF             := -19.05
   res@mpOutlineBoundarySets = "National"
   res@mpDataSetName         = "Earth..4"
   res@mpDataBaseVersion     = "MediumRes"
   res@mpOutlineOn           = True
   res@mpOutlineSpecifiers   = (/"Brazil:states"/)
   res@cnLevelSelectionMode  = "ExplicitLevels"
   res@cnLevels              := intervalo_valores
   res@cnFillColors          := cores
   res@cnLinesOn             = False
   res@cnLineLabelsOn        = False
   res@gsnAddCyclic          = False
   res@mpLandFillColor       = "transparent"
   res@mpOceanFillColor      = "white"
   res@cnFillDrawOrder       = "PreDraw"
   res@mpFillDrawOrder       = "Draw"
   res@tmXBOn                = False
   res@tmXTOn                = False
   res@tmYLOn                = False
   res@tmYROn                = False
   res@mpOutlineBoundarySets = "NoBoundaries" ; Não desenha os limites dos países.
   res@gsnStringFontHeightF  = 0.04

   ; Personalização da linha do shapefile.
   lnres                  = True
   lnres@gsLineColor      = "black"
   lnres@gsLineThicknessF = 3.0

   do i = 0,3
      printMinMax(var(i,:,:),False)
      res@gsnCenterString = mes(i)
      plot(i) = gsn_csm_contour_map(wks,var(i,:,:),res) 
   end do

   line_mask = gsn_add_shapefile_polylines(wks,plot,"../shape/shp/Area_PARNA_SerraCipo.shp",lnres)

   resP                             = True
   resP@gsnPanelLabelBar            = True
   resP@gsnMaximize                 = True
   resP@lbTitleOn                   = True
   resP@lbTitleString              := unidade
   resP@lbTitleFontHeightF          = 0.017
   resP@lbLabelFontHeightF          = 0.017
   resP@pmLabelBarOrthogonalPosF    = -0.03
   resP@gsnPanelXWhiteSpacePercent  = 5
   resP@gsnPanelYWhiteSpacePercent  = 5
   resP@pmLabelBarWidthF            = 0.6
   resP@pmLabelBarHeightF           = 0.07
   resP@gsnPanelMainString          = "2020"

   gsn_panel(wks,plot,(/2,2/),resP)

   system("convert -trim ../figuras/"+nome_figura(j)+".png ../figuras/"+nome_figura(j)+".png")

end do

end
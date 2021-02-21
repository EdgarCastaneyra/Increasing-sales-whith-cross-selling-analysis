*application.Visible=.f.
CLOSE TABLES
SET safety OFF
SET TALK OFF
SET DATE FRENCH
SET CENTURY on
SET STATUS BAR OFF
SET DEFAULT TO SYS(5) + LEFT(SYS(2003),LEN(SYS(2003)))


****** configuración de variables publicas*****
PUBLIC rutavsai,rutadata


STORE "C:\Users\edg19\Dashboard\Data\" TO rutadata
STORE "C:\Users\edg19\Dashboard\Programa Fox\Tablas\" TO rutavsai



************************ Tabla maestra Productos **********************
		USE rutavsai + "ventas.dbf" IN 0
		USE rutavsai + "producto.dbf" IN 0
		
		SELECT fecha,DAY(fecha) DIA,MONTH(fecha) MES,YEAR(fecha) ANIO,cve_prod,vent_net imp_tot,cost_prom,cant_surt cant_ven,cant_dev,fac,cve_suc,ALLTRIM(cve_suc) + ALLTRIM(fac) llave,space(1) documento FROM ventas INTO TABLE paso1
		
		replace ALL fecha WITH DATE(anio,mes,1)

		************ cruce con catalogo de productos **************
		ALTER table paso1 ADD COLUMN cse_prod c(10)
		ALTER table paso1 ADD COLUMN sub_cse c(10)
		ALTER table paso1 ADD COLUMN sub_subcse c(10)
		ALTER table paso1 ADD COLUMN desc_prod c(40)
		ALTER table paso1 ADD COLUMN des_tial c(40)
		ALTER table paso1 ADD COLUMN cve_tial n(10)
		ALTER table paso1 ADD COLUMN uni_med c(5)

		SELECT producto
		INDEX on cve_prod TO a
		SELECT paso1
		SET RELATION TO cve_prod INTO producto
		replace ALL uni_med WITH producto.uni_med 
		replace ALL cse_prod WITH producto.cse_prod
		replace ALL sub_cse WITH producto.sub_cse 
		replace ALL sub_subcse WITH producto.sub_subcse 
		replace ALL desc_prod WITH producto.desc_prod 
		replace ALL cve_tial WITH producto.cve_tial 
		select producto
		USE
		
		
		**************Tipo Producto****************

		USE rutavsai + "tipoalma" IN 0 EXCLUSIVE
		SELECT tipoalma
		INDEX on cve_tial TO a
		SELECT paso1
		SET RELATION TO cve_tial inTO tipoalma
		replace ALL des_tial WITH tipoalma.des_tial
		SELECT tipoalma
		USE
				
		***********************************crea tabla final **********************************************
		
		SELECT distinct(cve_prod) cve_prod,cse_prod,sub_cse,sub_subcse,desc_prod,des_tial,cve_tial,uni_med,des_tial;
		,SPACE(20) cve_p_a,SPACE(60) desc_p_a,(0.00) corr_a,SPACE(20) cve_p_b,SPACE(60) desc_p_b,(0.00) corr_b,SPACE(20) cve_p_c,SPACE(60) desc_p_c,(0.00) corr_c;
		,SPACE(20) cve_p_d,SPACE(60) desc_p_d,(0.00) corr_d,(0000000000) prod_rel FROM paso1 INTO TABLE relacionprod
		
		************************************creas query para sacar correlacion cantidad de producto*********************
		SELECT cve_prod FROM relacionprod INTO TABLE listaprod
		SELECT listaprod
		GO top IN listaprod
		DO WHILE !EOF('listaprod')

			prodbase=listaprod.cve_prod
			SELECT distinct(llave) llave FROM paso1 where cve_prod=prodbase INTO TABLE iddoc
			SELECT paso1.llave,paso1.cve_prod,imp_tot,cant_ven FROM paso1 right JOIN iddoc ON iddoc.llave==paso1.llave INTO TABLE filtrado
			*DROP TABLE iddoc
			SELECT llave,cant_ven a FROM filtrado WHERE cve_prod=prodbase INTO TABLE compbase
			SELECT distinct(cve_prod) cve_prod,(0.0000) corr FROM filtrado WHERE cve_prod<>prodbase INTO TABLE catcorr

				SELECT catcorr			
				GO top IN catcorr
				IF NOT EMPTY(catcorr.cve_prod) then
				DO WHILE !EOF('catcorr') 

					prodcompara=catcorr.cve_prod
					
							
					SELECT llave,cant_ven b FROM filtrado WHERE cve_prod=prodcompara INTO table compcomp
					

					SELECT compbase.llave,compbase.a a,compcomp.b b,(000000000000000.00) sumaa,(000000000000000.00) sumab,(000000000000000.00) proma,(000000000000000.00) promb,(000000000000000.00) conteo;
					FROM compbase right JOIN compcomp ON compbase.llave==compcomp.llave GROUP BY 1,2,3 INTO TABLE corre
					
					SELECT SUM(a) sumaa,sum(b) sumab,AVG(a) proma,AVG(b) promb,COUNT(a) conteo FROM corre INTO TABLE sumas
					
					SELECT corre
					replace ALL sumaa WITH sumas.sumaa
					replace ALL sumab WITH sumas.sumab
					replace ALL proma WITH sumas.proma 
					replace ALL promb WITH sumas.promb
					replace ALL conteo WITH sumas.conteo
					n=sumas.conteo
					
					DROP TABLE compcomp
					DROP TABLE sumas
					
					SELECT SUM((a-proma)^2) desvesta,SUM((b-promb)^2) desvestb,SUM((a-proma)*(b-promb)) corr FROM corre INTO TABLE paso

					SELECT paso
					replace desvesta WITH SQRT(desvesta/n)
					replace ALL desvestb WITH SQRT(desvestb/n)
					replace ALL corr WITH (corr/n)

					GO TOP IN paso
					
					IF (paso.desvesta*paso.desvestb)==0 THEN 
					replace ALL corr WITH 0
					ELSE
					replace ALL corr WITH corr/(paso.desvesta*paso.desvestb)
					ENDIF

					GO TOP IN paso								
					correlacion=paso.corr
					
					
					SELECT catcorr
					replace corr WITH paso.corr
					
				SKIP 1 IN catcorr
				ENDDO 
					
				SELECT * FROM catcorr WHERE ABS(corr)>=.8 ORDER BY corr DESC INTO TABLE corrfin
				
				ON ERROR 	
				DROP TABLE paso
				DROP TABLE corre
				DROP TABLE filtrado
				DROP TABLE iddoc
				DROP TABLE compbase
				DROP TABLE catcorr
	
				SELECT corrfin
				COUNT TO prel

				SELECT relacionprod	
				GO TOP IN relacionprod		
				replace prod_rel WITH prel
								
				GO TOP IN corrfin
				y=IIF(prel<4,prel,4)
					
					IF not EMPTY(corrfin.cve_prod) then			
						FOR x = 1 TO y


							cve=corrfin.cve_prod
							cor=corrfin.corr
								
							SELECT relacionprod 
							
								DO CASE 
								
								CASE x=1				
									replace cve_p_a WITH cve FOR cve_prod=prodbase
									replace corr_a WITH cor FOR cve_prod=prodbase
									
								CASE x=2				
									replace cve_p_b WITH cve FOR cve_prod=prodbase
									replace corr_b WITH cor FOR cve_prod=prodbase
								CASE x=3				
									replace cve_p_c WITH cve FOR cve_prod=prodbase
									replace corr_c WITH cor FOR cve_prod=prodbase
								CASE x=4				
									replace cve_p_d WITH cve FOR cve_prod=prodbase
									replace corr_d WITH cor FOR cve_prod=prodbase
									
								ENDCASE
							
						
						SKIP 1 IN corrfin
						NEXT
					ENDIF
				ENDIF
				
		SKIP 1 IN listaprod
	
		ENDDO
	
		DROP TABLE listaprod
		DROP TABLE corrfin

		SELECT relacionprod	
SET STEP ON		

		USE rutavsai + "producto.dbf" IN 0		
		SELECT producto
		INDEX on cve_prod TO a
		SELECT relacionprod
		SET RELATION TO cve_p_a INTO producto	
		replace ALL desc_p_a WITH desc_prod FOR relacionprod.cve_p_a==producto.cve_prod 
		SET RELATION TO 
		

		SELECT relacionprod
		SET RELATION TO cve_p_b INTO producto	
		replace all desc_p_b WITH desc_prod  FOR relacionprod.cve_p_b==producto.cve_prod 
		SET RELATION TO 
		
		SELECT relacionprod
		SET RELATION TO cve_p_c INTO producto	
		replace all desc_p_c WITH desc_prod  FOR relacionprod.cve_p_c==producto.cve_prod 
		SET RELATION to	
		
		SELECT relacionprod
		SET RELATION TO cve_p_d INTO producto	
		replace ALL desc_p_d WITH desc_prod FOR relacionprod.cve_p_d==producto.cve_prod 
		SET RELATION to
		
		SELECT producto 
		use

		SELECT relacionprod		
		COPY TO "C:\Users\edg19\Dashboard\Estadistica\" + "rel_cant.xls" TYPE foxplus


		************************************creas query para sacar correlacion*********************
		SELECT distinct(cve_prod) cve_prod,cse_prod,sub_cse,sub_subcse,desc_prod,des_tial,cve_tial,uni_med,des_tial;
		,SPACE(20) cve_p_a,SPACE(60) desc_p_a,(0.00) corr_a,SPACE(20) cve_p_b,SPACE(60) desc_p_b,(0.00) corr_b,SPACE(20) cve_p_c,SPACE(60) desc_p_c,(0.00) corr_c;
		,SPACE(20) cve_p_d,SPACE(60) desc_p_d,(0.00) corr_d,(0000000000) prod_rel FROM paso1 INTO TABLE relacionprod
		
		SELECT cve_prod FROM relacionprod INTO TABLE listaprod
		SELECT listaprod
		GO top IN listaprod
		DO WHILE !EOF('listaprod')

			prodbase=listaprod.cve_prod
			SELECT distinct(llave) llave FROM paso1 where cve_prod=prodbase INTO TABLE iddoc
			SELECT iddoc
			COUNT TO conteo

			SELECT paso1.llave,paso1.cve_prod,imp_tot,cant_ven FROM paso1 right JOIN iddoc ON iddoc.llave==paso1.llave INTO TABLE filtrado


			SELECT cve_prod,COUNT(cve_prod)/conteo participa FROM filtrado WHERE cve_prod<>prodbase GROUP BY 1 INTO TABLE participacion


				SELECT * FROM participacion WHERE ABS(participa)>=.2 ORDER BY participa DESC INTO TABLE corrfin
				
				DROP TABLE filtrado
				DROP TABLE iddoc
				DROP TABLE participacion
	
				SELECT corrfin
				COUNT TO prel

				SELECT relacionprod	
				GO TOP IN relacionprod		
				replace prod_rel WITH prel
								
				GO TOP IN corrfin
				y=IIF(prel<4,prel,4)
					
					IF not EMPTY(corrfin.cve_prod) then			
						FOR x = 1 TO y

							cve=corrfin.cve_prod
							participa=corrfin.participa
								
							SELECT relacionprod 
							
								DO CASE 
								
								CASE x=1				
									replace cve_p_a WITH cve FOR cve_prod=prodbase
									replace corr_a WITH participa FOR cve_prod=prodbase
									replace corr_a WITH 1 FOR corr_a>1
									
								CASE x=2				
									replace cve_p_b WITH cve FOR cve_prod=prodbase
									replace corr_b WITH participa FOR cve_prod=prodbase
									replace corr_b WITH 1 FOR corr_b>1
									
								CASE x=3				
									replace cve_p_c WITH cve FOR cve_prod=prodbase
									replace corr_c WITH participa FOR cve_prod=prodbase
									replace corr_c WITH 1 FOR corr_c>1
									
								CASE x=4				
									replace cve_p_d WITH cve FOR cve_prod=prodbase
									replace corr_d WITH participa FOR cve_prod=prodbase
									replace corr_d WITH 1 FOR corr_d>1

								ENDCASE
							
						
						SKIP 1 IN corrfin
						NEXT
					ENDIF

				
		SKIP 1 IN listaprod

		ENDDO
		DROP TABLE listaprod
		DROP TABLE corrfin
		
		SELECT relacionprod	
		

		USE rutavsai + "producto.dbf" IN 0		
		SELECT producto
		INDEX on cve_prod TO a
		SELECT relacionprod
		SET RELATION TO cve_p_a INTO producto	
		replace ALL desc_p_a WITH desc_prod FOR relacionprod.cve_p_a==producto.cve_prod 
		SET RELATION TO 
		

		SELECT relacionprod
		SET RELATION TO cve_p_b INTO producto	
		replace all desc_p_b WITH desc_prod  FOR relacionprod.cve_p_b==producto.cve_prod 
		SET RELATION TO 
		
		SELECT relacionprod
		SET RELATION TO cve_p_c INTO producto	
		replace all desc_p_c WITH desc_prod  FOR relacionprod.cve_p_c==producto.cve_prod 
		SET RELATION to	
		
		SELECT relacionprod
		SET RELATION TO cve_p_d INTO producto	
		replace ALL desc_p_d WITH desc_prod FOR relacionprod.cve_p_d==producto.cve_prod 
		SET RELATION to
		
		SELECT producto 
		use

		SELECT relacionprod	
		COPY TO "C:\Users\edg19\Dashboard\Estadistica\" + "rel_novtas.xls" TYPE foxplus
		
		
*!*			************************************creas query para sacar correlacion monto de la venta*********************
		SELECT distinct(cve_prod) cve_prod,cse_prod,sub_cse,sub_subcse,desc_prod,des_tial,cve_tial,uni_med,des_tial;
		,SPACE(20) cve_p_a,SPACE(60) desc_p_a,(0.00) corr_a,SPACE(20) cve_p_b,SPACE(60) desc_p_b,(0.00) corr_b,SPACE(20) cve_p_c,SPACE(60) desc_p_c,(0.00) corr_c;
		,SPACE(20) cve_p_d,SPACE(60) desc_p_d,(0.00) corr_d,(0000000000) prod_rel FROM paso1 INTO TABLE relacionprod


		SELECT cve_prod FROM relacionprod INTO TABLE listaprod
		SELECT listaprod
		GO top IN listaprod
		DO WHILE !EOF('listaprod')

			prodbase=listaprod.cve_prod
			SELECT distinct(llave) llave FROM paso1 where cve_prod=prodbase INTO TABLE iddoc
			SELECT paso1.llave,paso1.cve_prod,imp_tot,cant_ven FROM paso1 right JOIN iddoc ON iddoc.llave==paso1.llave INTO TABLE filtrado
			*DROP TABLE iddoc
			SELECT llave,imp_tot a FROM filtrado WHERE cve_prod=prodbase INTO TABLE compbase
			SELECT distinct(cve_prod) cve_prod,(0.0000) corr FROM filtrado WHERE cve_prod<>prodbase INTO TABLE catcorr

				SELECT catcorr			
				GO top IN catcorr
				IF NOT EMPTY(catcorr.cve_prod) then
				DO WHILE !EOF('catcorr') 

					prodcompara=catcorr.cve_prod
					
							
					SELECT llave,imp_tot b FROM filtrado WHERE cve_prod=prodcompara INTO table compcomp
					

					SELECT compbase.llave,compbase.a a,compcomp.b b,(000000000000000.00) sumaa,(000000000000000.00) sumab,(000000000000000.00) proma,(000000000000000.00) promb,(000000000000000.00) conteo;
					FROM compbase right JOIN compcomp ON compbase.llave==compcomp.llave GROUP BY 1,2,3 INTO TABLE corre
					
					SELECT SUM(a) sumaa,sum(b) sumab,AVG(a) proma,AVG(b) promb,COUNT(a) conteo FROM corre INTO TABLE sumas
					
					SELECT corre
					replace ALL sumaa WITH sumas.sumaa
					replace ALL sumab WITH sumas.sumab
					replace ALL proma WITH sumas.proma 
					replace ALL promb WITH sumas.promb
					replace ALL conteo WITH sumas.conteo
					n=sumas.conteo
					
					DROP TABLE compcomp
					DROP TABLE sumas
					
					SELECT SUM((a-proma)^2) desvesta,SUM((b-promb)^2) desvestb,SUM((a-proma)*(b-promb)) corr FROM corre INTO TABLE paso

					SELECT paso
					replace desvesta WITH SQRT(desvesta/n)
					replace ALL desvestb WITH SQRT(desvestb/n)
					replace ALL corr WITH (corr/n)

					GO TOP IN paso
					
					IF (paso.desvesta*paso.desvestb)==0 THEN 
					replace ALL corr WITH 0
					ELSE
					replace ALL corr WITH corr/(paso.desvesta*paso.desvestb)
					ENDIF

					GO TOP IN paso								
					correlacion=paso.corr
					
					
					SELECT catcorr
					replace corr WITH paso.corr
					
				SKIP 1 IN catcorr
				ENDDO 
					
				SELECT * FROM catcorr WHERE ABS(corr)>=.8 ORDER BY corr DESC INTO TABLE corrfin
				
				ON ERROR 	
				DROP TABLE paso
				DROP TABLE corre
				DROP TABLE filtrado
				DROP TABLE iddoc
				DROP TABLE compbase
				DROP TABLE catcorr
	
				SELECT corrfin
				COUNT TO prel

				SELECT relacionprod	
				GO TOP IN relacionprod		
				replace prod_rel WITH prel
								
				GO TOP IN corrfin
				y=IIF(prel<4,prel,4)
					
					IF not EMPTY(corrfin.cve_prod) then			
						FOR x = 1 TO y


							cve=corrfin.cve_prod
							cor=corrfin.corr
								
							SELECT relacionprod 
							
								DO CASE 
								
								CASE x=1				
									replace cve_p_a WITH cve FOR cve_prod=prodbase
									replace corr_a WITH cor FOR cve_prod=prodbase
									
								CASE x=2				
									replace cve_p_b WITH cve FOR cve_prod=prodbase
									replace corr_b WITH cor FOR cve_prod=prodbase
								CASE x=3				
									replace cve_p_c WITH cve FOR cve_prod=prodbase
									replace corr_c WITH cor FOR cve_prod=prodbase
								CASE x=4				
									replace cve_p_d WITH cve FOR cve_prod=prodbase
									replace corr_d WITH cor FOR cve_prod=prodbase
									
								ENDCASE
							
						
						SKIP 1 IN corrfin
						NEXT
					ENDIF
				ENDIF
				
		SKIP 1 IN listaprod

		ENDDO
	
		DROP TABLE listaprod
		DROP TABLE corrfin

		SELECT relacionprod	
		

		USE rutavsai + "producto.dbf" IN 0		
		SELECT producto
		INDEX on cve_prod TO a
		SELECT relacionprod
		SET RELATION TO cve_p_a INTO producto	
		replace ALL desc_p_a WITH desc_prod FOR relacionprod.cve_p_a==producto.cve_prod 
		SET RELATION TO 
		

		SELECT relacionprod
		SET RELATION TO cve_p_b INTO producto	
		replace all desc_p_b WITH desc_prod  FOR relacionprod.cve_p_b==producto.cve_prod 
		SET RELATION TO 
		
		SELECT relacionprod
		SET RELATION TO cve_p_c INTO producto	
		replace all desc_p_c WITH desc_prod  FOR relacionprod.cve_p_c==producto.cve_prod 
		SET RELATION to	
		
		SELECT relacionprod
		SET RELATION TO cve_p_d INTO producto	
		replace ALL desc_p_d WITH desc_prod FOR relacionprod.cve_p_d==producto.cve_prod 
		SET RELATION to
		
		SELECT producto 
		use

		SELECT relacionprod		
		COPY TO "C:\Users\edg19\Dashboard\Estadistica\" + "rel_monto.xls" TYPE foxplus

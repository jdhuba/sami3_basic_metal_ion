      SUBROUTINE SEVP(AX,AY,CX,CY,BB,RINV,RINV1,RCOR,NBSIZ2,IS,IE,INX,
     1SUMF,DUMMY1,RTILDA,X,F,ERR,F11,F1N,F21,F2M,M,N,M1,N1,M2,N2,
     2NBLK,NBLK1,B1,B2,A11,A1N,A21,A2M,ICY,TOL,IFLG,MX,NX)

      REAL*8 RINV,RINV1,RCOR,RTILDA,X,DUMMY1,B1,B2
      REAL*8 F,ERR
      REAL*8 AX,AY,CX,CY,BB

!      REAL RINV,RINV1,RCOR,RTILDA,X,DUMMY1,B1,B2
!      REAL F,ERR
!      REAL AX,AY,CX,CY,BB

      DIMENSION AX(MX,NX),AY(MX,NX),CX(MX,NX),CY(MX,NX),BB(MX,NX)
      DIMENSION RINV(M2,M2,NBLK),RINV1(M2,M2,NBLK1),RCOR(M,3)
      DIMENSION RTILDA(M2),NBSIZ2(NBLK),IS(NBLK),IE(NBLK),SUMF(NBLK)
      DIMENSION X(MX,NX),F(MX,NX),ERR(MX,NX)
      DIMENSION F11(M),F1N(M),F21(N),F2M(N)
      DIMENSION INX(M)
      DIMENSION DUMMY1(M2,M2)
      DIMENSION B1(M2),B2(M2)
C
C COMPUTE NUMBER OF BOUNDARIES WITH NEUMAN B.C.
 
      NEUM = INT(A11+A1N+A21+A2M)
      IPT = 0
C TEST FOR 4-SIDED NEUMAN, OR 2-SIDED NEUMAN AND CYCLIC BC'S
      IF(NEUM .EQ. 4) IPT=1
      IF(ICY.EQ.1 .AND. NEUM.EQ.2) IPT=1

C
C INTERNAL PARAMETERS
C
C TO PRINT ERRORS AFTER EACH ITERATION, SET IOUT=1, OTHERWISE IOUT=0.
      IOUT = 0
C EPS IS SET TO PRECISION OF COMPUTER
C EPS FOR CRAY 64 BIT SINGLE PRECISION FLOATING POINT WORDS
      EPS=0.5E-14
C SET MAXIMUM FOR NUMBER OF POINTS ALLOWED IN EACH BLOCK
      MAXSIZ=14
C
C FOR 4-SIDED NEUMAN, OR 2-SIDED NEUMAN WITH CYCLIC BC'S (WHEN IPT=1),
C A BOUNDARY VALUE MUST BE PRESCIBED AT POINT (IX, JX) FOR A 
C SOLUTION TO BE OBTAINED. JF IS NEAREST INTERIOR ROW TO PRESCRIBED
C BOUNDARY POINT.
C COORDINATES FOR PRESCRIBED BOUNDARY VALUE (WHEN IPT=1)
      IX = 2
 27   JX = 1
C NEAREST INTERIOR ROW TO BOUNDARY POINT (IX,JX)
      JF=2
C
C     SOLVER TOLERANCE NO SMALLER THAN EPS*100.
      TOL=AMAX1(TOL,EPS*100.)
C
C DEFINE I INDICES TO BE USED FOR SOLUTION VARIABLES AT I-1, I+1 IN 
C DIFFERENCE EQUATION.
      DO 5 I = 1,M
      INX(I) = I
    5 CONTINUE
C For cyclic Boundary Conditions
      IF(ICY .EQ. 1) THEN
      A21 = 0.0
      A2M = 0.0
      INX(1) = M-1
      INX(M)  =  2
      ENDIF
C
C SET SIZE OF EACH BLOCK
C     NBSIZ2() IS NUMBER OF INTERNAL POINTS IN BLOCK
      CALL BLKSIZ(NBSIZ2,NBLK,NBLK1,N,A1N,MAXSIZ)
C DEFINE BLOCK BOUNDARIES
C     IE() IS END OF EACH BLOCK
      IE(1)=NBSIZ2(1)+2
      IF(NBLK .EQ. 1) GOTO 16
      DO 10 NB=2,NBLK
      IE(NB)=IE(NB-1)+NBSIZ2(NB)+1
   10 CONTINUE
C     IS() IS START OF EACH BLOCK
      DO 15 NB=1,NBLK1
      IS(NB+1)=IE(NB)-1
   15 CONTINUE
   16 CONTINUE
      IS(1)=1
C
C SUM MAGNITUDE OF THE FORCING IN LAST INTERIOR ROW OF EACH BLOCK
      DO 20 NB=1,NBLK
      SUMF(NB)=0.0
   20 CONTINUE
      DO 127 NB=1,NBLK
      IENB1=IE(NB)-1
      DO 25 I=2,M1
      SUMF(NB)=SUMF(NB)+ABS(F(I,IENB1))
   25 CONTINUE
  127 CONTINUE
      DO 26 NB=1,NBLK
      IF(SUMF(NB).GT.0.0) GO TO 26
CCKS      SUMF(NB)=1.0
      SUMF(NB)=1.0*FLOAT(M-2)
   26 CONTINUE
C
C INCORPORATE NEUMAN BC'S AT I BOUNDARIES IN DIFFERENCE EQUATION,
C REPLACING WITH HOMOGENEOUS DIRCHLET BC'S.
      DO 101 J=2,N1
      BB(2,J)=BB(2,J)+AX(2,J)*A21
      F(2,J)=F(2,J)+AX(2,J)*F21(J)*A21
      X(1,J)=(1.0-A21)*X(1,J)
      BB(M-1,J)=BB(M-1,J)+CX(M-1,J)*A2M
      F(M-1,J)=F(M-1,J)-CX(M-1,J)*F2M(J)*A2M
      X(M,J)=(1.0-A2M)*X(M,J)
  101 CONTINUE
C
C INCORPORATE NEUMAN BC'S AT J BOUNDARIES IN DIFFERENCE EQUATION,
C REPLACING WITH HOMOGENEOUS DIRCHLET BC'S, EXCEPT FOR PRESCRIBED
C BOUNDARY POINT WHEN IPT=1.
C INCLUDE DIRICHLET BC AT J=N IN FORCING FUNCTION ON J=N-1 ROW,
C REPLACING WITH HOMOGENEOUS DIRCHLET BC.
C  SPACE X(I,N) NOT USED FOR SOLVER (X(I,N)=0. ASSUMED), USE
C  SPACE TO SAVE ORIGINAL BOUNDARY VALUE AT J=N.
      IF(IPT .EQ. 1) THEN
      AB=BB(IX,JF)
      AB1=X(IX,JX)
      AB2=F(IX,JF)
      END IF
      DO 102 I=2,M1
      BB(I,2)=BB(I,2)+AY(I,2)*A11
      F(I,2)=F(I,2)+AY(I,2)*F11(I)*A11
      X(I,1)=(1.0-A11)*X(I,1)
      BB(I,N-1)=BB(I,N-1)+CY(I,N-1)*A1N
      F(I,N-1)=F(I,N-1)-CY(I,N-1)*(F1N(I)*A1N+(1.0-A1N)*X(I,N))
      X(I,N)=(1.0-A1N)*X(I,N)
  102 CONTINUE
      IF(IPT .EQ. 1) THEN
      BB(IX,JF)=AB
      X(IX,JX)=AB1
      F(IX,JF)=AB2
      IF(JX .EQ. N) F(IX,N-1)=F(IX,N-1)-CY(IX,N-1)*X(IX,N)
      END IF
C
      IF(IOUT .EQ. 1) PRINT 750
  750 FORMAT(1X//,' ERROR VECTOR PROPAGATION METHOD')
C
C   CALL PREPROCESSOR
C
      IF(IFLG.NE.1)GO TO 103
      CALL  BSM1(AX,AY,BB,CX,CY,RINV,RINV1,RCOR,DUMMY1,
     1NBSIZ2,IS,IE,INX,M,N,M1,N1,M2,N2,NBLK,NBLK1,B1,B2,MX,NX)
  103 CONTINUE
C
C CALL STABILIZED ERROR VECTOR PROPAGATION METHOD
C
      CALL BSM2(AX,AY,BB,CX,CY,RINV,RINV1,RCOR,F,X,RTILDA,TOL,
     1SUMF,IS,IE,INX,M,N,M1,N1,M2,N2,NBLK,NBLK1,IOUT,MX,NX)
C
C               DEFINE SOLUTION BOUNDARY VALUES
C
      DO 350 J=2,N1
      X(1,J)=(1.0-A21)*X(1,J)+A21*(X(2,J)-F21(J))
      X(M,J)=(1.0-A2M)*X(M,J)+A2M*(X(M-1,J)+F2M(J))
  350 CONTINUE
C
      IF(IPT .EQ. 1) AB1=X(IX,JX)
      DO 360 I=2,M1
      X(I,1)=(1.0-A11)*X(I,1)+A11*(X(I,2)-F11(I))
      X(I,N)=(1.0-A1N)*X(I,N)+A1N*(X(I,N-1)+F1N(I))
  360 CONTINUE
      IF(IPT .EQ. 1) X(IX,JX)=AB1
C
      IF(ICY .EQ. 1) THEN
CCKS      DO 354 J=2,N1
      DO 354 J=1,N
      X(1,J) = X(M-1,J)
      X(M,J) = X(2,J)
  354 CONTINUE
      ENDIF
C
C RESET FINITE DIFFERENCE MATRIX COEFFICIENTS AND FORCING
C BACK TO INPUT VALUES
C
      DO 371 J=2,N1
      BB(2,J)=BB(2,J)-AX(2,J)*A21
      F(2,J)=F(2,J)-AX(2,J)*F21(J)*A21
      BB(M-1,J)=BB(M-1,J)-CX(M-1,J)*A2M
      F(M-1,J)=F(M-1,J)+CX(M-1,J)*F2M(J)*A2M
  371 CONTINUE
C
      IF(IPT .EQ. 1) THEN
       AB=BB(IX,JF)
       AB2=F(IX,JF)
      END IF
      DO 372 I=2,M1
      BB(I,2)=BB(I,2)-AY(I,2)*A11
      F(I,2)=F(I,2)-AY(I,2)*F11(I)*A11
      BB(I,N-1)=BB(I,N-1)-CY(I,N-1)*A1N
      F(I,N-1)=F(I,N-1)+CY(I,N-1)*(F1N(I)*A1N+(1.0-A1N)*X(I,N))
  372 CONTINUE
      IF(IPT .EQ. 1) THEN
       BB(IX,JF)=AB
       F(IX,JF)=AB2
      END IF
C
C     RESIDUAL ERROR
C
      DO 740 I=2,M1
      DO 740 J=2,N1
      ERR(I,J)=F(I,J)-AY(I,J)*X(I,J-1)-AX(I,J)*X(INX(I-1),J)
     1-BB(I,J)*X(I,J)-CX(I,J)*X(INX(I+1),J)-CY(I,J)*X(I,J+1)
  740 CONTINUE
C
      RETURN
      END
      SUBROUTINE BLKSIZ(NBSIZ2,NBLK,NBLK1,N,A1N,MAXSIZ)
      DIMENSION NBSIZ2(NBLK)
C
C  COMPUTE NUMBER OF INTERIOR POINTS IN EACH BLOCK
C
C NUMBER OF BLOCK BOUNDARIES IS NBLK+1
C NUMBER OF INTERIOR BLOCK POINTS IS N-NBLK-1
C
      IF(NBLK .EQ. 1)THEN
      NBSIZ2(1) = N-2
      GOTO 160
      ENDIF
C
      IF(INT(A1N) .EQ. 1) THEN
        NBSIZ2(NBLK)=4
        NSIZE = (N-NBLK-1-4)/NBLK1
        DO 100 NB=1,NBLK1
           NBSIZ2(NB) = NSIZE
  100   CONTINUE
        NBLEFT=N-NBLK-1-4-NBLK1*NSIZE
      ELSE
        NSIZE=(N-NBLK-1)/NBLK
        DO 120 NB=1,NBLK
           NBSIZ2(NB)=NSIZE
  120   CONTINUE
        NBLEFT=N-NBLK-1-NBLK*NSIZE
      ENDIF
      IF(NBLEFT .EQ. 0)GO TO 151
      DO 150 NB=1,NBLEFT
         NBSIZ2(NB)=NBSIZ2(NB)+1
  150 CONTINUE
  151 CONTINUE
C
  160 CONTINUE
C
C CHECK BLOCK SIZES LESS THAN MAXSIZ
C
      DO 200 NB=1,NBLK
      IA=3
      IF(NB .EQ. 1)IA=2
      IF(NBSIZ2(NB)+IA .GT. MAXSIZ) GOTO 210
  200 CONTINUE
      GOTO 250
  210 PRINT 710, MAXSIZ
  710 FORMAT(1X,'***** WARNING: BLOCK(S) LARGER THAN MAXSIZ =',
     1   I3,', INCREASE NUMBER OF BLOCKS *****')
      PRINT 720 
  720 FORMAT(1X,'BLOCK SIZE GIVEN BY NBSIZ2+2 (FIRST BLOCK) OR',
     1 ' NBSIZ2+3 (SUBSEQUENT BLOCKS)',1X/,'  NBSIZ2: ')
      PRINT 730, (NBSIZ2(NB),NB=1,NBLK)
  730 FORMAT(1X,15I4)
  250 CONTINUE
C
      RETURN
      END
      SUBROUTINE BSM1(AX,AY,BB,CX,CY,RINV,RINV1,RCOR,DUMMY1,
     1NBSIZ2,IS,IE,INX,M,N,M1,N1,M2,N2,NBLK,NBLK1,B1,B2,MX,NX)

      REAL*8 RINV,RINV1,RCOR,DUMMY1,B1,B2
      REAL*8 AX,AY,CX,CY,BB

!      REAL RINV,RINV1,RCOR,DUMMY1,B1,B2
!      REAL AX,AY,CX,CY,BB

      DIMENSION AX(MX,NX),AY(MX,NX),CX(MX,NX),CY(MX,NX),BB(MX,NX)
      DIMENSION RINV(M2,M2,NBLK),RINV1(M2,M2,NBLK1),RCOR(M,3)
      DIMENSION NBSIZ2(NBLK),IS(NBLK),IE(NBLK),INX(M)
      DIMENSION DUMMY1(M2,M2)
      DIMENSION B1(M2),B2(M2) 
C
C     PREPROCESSOR : CALCULATION OF INFLUENCE AND RESIDUAL MATRICES
C
C    RINV(,,NB), NB=1,...,NBLK-1
C    INVERSE INFLUENCE MATRICES, FOR BLOCKS 1 TO NBLK-1 ,WHICH
C    RELATE THE SOLUTION ERROR ON THE SECOND AND LAST ROW FOR EACH 
C    BLOCK.
C    RINV(,,NBLK)
C    THE INVERSE OF THE RESIDUAL R MATRIX RELATING THE RESIDUAL ERROR COMPUTED
C    ON THE LAST INTERIOR ROW J=N-1 TO THE SOLUTION ERROR ON THE SECOND ROW
C    OF THE LAST BLOCK.
C    RINV1(,,NB), NB=1,...,NBLK-1
C    INVERSE INFLUENCE MATRICES, FOR BLOCKS 1 TO NBLK-1, WHICH RELATE THE 
C    SOLUTION ERROR ON THE LAST TWO ROWS OF THE BLOCK.
C
C INFLUENCE MATRICES FOR FIRST BLOCK
C
C Influence matrices, relating the solution error on the second row
C  to the last two rows of the block, are computed by marching M-2 unit row
C  vectors to the end of the block.
      DO 115 I1=1,M2
C UNIT ROW VECTOR with (I1+1)th element one
      DO 110 J=1,3
      DO 110 I=1,M
      RCOR(I,J)=0.0
  110 CONTINUE
      RCOR(I1+1,2)=1.0
C MARCH UNIT ROW VECTOR FROM SECOND ROW TO END OF BLOCK J=IE(1).
C FOR SINGLE BLOCK, MARCH TO J=N-1 only.
      NBS=IE(1)-1
      IF(NBLK.EQ.1)NBS=N-2
      DO 130 J1=2,NBS
      DO 135 I=2,M1
      RCOR(I,3)=(-AX(I,J1)*RCOR(INX(I-1),2)-AY(I,J1)*RCOR(I,1)
     1-BB(I,J1)*RCOR(I,2)-CX(I,J1)*RCOR(INX(I+1),2))/CY(I,J1)
  135 CONTINUE
      DO 140 I=1,M
      RCOR(I,1)=RCOR(I,2)
      RCOR(I,2)=RCOR(I,3)
  140 CONTINUE
  130 CONTINUE
      IF(NBLK.EQ.1) GOTO 146
C Rows of first and second INFLUENCE MATRICES defined by row vectors on
C last two rows J=IE(1)-1, IE(1), respectively.
      DO 145 I=1,M2
      RINV(I1,I,1)=RCOR(I+1,1)
      DUMMY1(I1,I)=RCOR(I+1,2)
  145 CONTINUE
      GOTO 149
  146 CONTINUE
C FOR SINGLE BLOCK Rows of RESIDUAL MATRIX defined by RESIDUALS
C COMPUTED ON LAST INTERIOR ROW J=N-1.
      DO 148 I=2,M1
      DUMMY1(I1,I-1)=AX(I,N-1)*RCOR(INX(I-1),2)+AY(I,N-1)*RCOR(I,1)
     1+BB(I,N-1)*RCOR(I,2)+CX(I,N-1)*RCOR(INX(I+1),2)
      RINV(I1,I-1,1)=DUMMY1(I1,I-1)
  148 CONTINUE
  149 CONTINUE
  115 CONTINUE
C
C Third Influence Matrix relating homogeneous solution on the last two 
C  rows of the block.
C INVERSE OF SECOND INFLUENCE MATRIX
      CALL MATINV(DUMMY1,B1,B2,M2)
      IF(NBLK.EQ.1) THEN
C RINV(,,1) IS INVERSE OF RESIDUAL MATRIX R FOR CASE NBLK=1
      DO 176 J=1,M2
      DO 176 I=1,M2
      RINV(I,J,1)=DUMMY1(I,J)
  176 CONTINUE
      ELSE
C RINV1(,,1), INVERSE OF 3RD INFLUENCE MATRIX IS GIVEN BY MATRIX 
C MULTIPLICATION OF INVERSE OF SECOND INFLUENCE MATRIX AND THE FIRST 
C INFLUENCE MATRIX.
      DO 160 I=1,M2
      DO 160 J=1,M2
      RINV1(I,J,1)=0.0
      DO 161 K=1,M2
      RINV1(I,J,1)=RINV1(I,J,1)+DUMMY1(I,K)*RINV(K,J,1)
  161 CONTINUE
  160 CONTINUE
C RINV(,,1) contains INVERSE OF second INFLUENCE MATRIX
      DO 170 I=1,M2
      DO 170 J=1,M2
      RINV(I,J,1)=DUMMY1(I,J)
  170 CONTINUE
      ENDIF
C
C INFLUENCE MATRICES FOR INTERIOR BLOCKS AND RESIDUAL MATRIX 
C   FOR LAST BLOCK
C
      IF(NBLK.EQ.1) GOTO 300
      DO 205 NB=2,NBLK
C MARCH TO END OF BLOCK FOR EACH UNIT ROW VECTOR
      DO 215 I1=1,M2
      DO 210 J=1,3
      DO 210 I=1,M
      RCOR(I,J)=0.0
  210 CONTINUE
C ROW VECTOR ON FIRST ROW OF BLOCK GIVEN BY UNIT VECTOR 
C         x INVERSE OF S MATRIX FROM PREVIOUS BLOCK
      DO 220 I=1,M2
      RCOR(I+1,1)=RINV1(I1,I,NB-1)
  220 CONTINUE
C UNIT VECTOR ON SECOND ROW OF BLOCK
      RCOR(I1+1,2)=1.0
      IE1=IE(NB-1)
      IE2=IE(NB)-1
      IF(NB.LT.NBLK) GO TO 232
      IE2=IE2-1
  232 CONTINUE
C MARCH UNIT VECTOR ON SECOND ROW TO END OF BLOCK, J=IE(NB), EXCEPT TO 
C  NEXT TO LAST ROW J=IE(NB)-1 FOR LAST BLOCK
      DO 230 J1=IE1,IE2
      DO 235 I=2,M1
      RCOR(I,3)=(-AX(I,J1)*RCOR(INX(I-1),2)-AY(I,J1)*RCOR(I,1)
     1-BB(I,J1)*RCOR(I,2)-CX(I,J1)*RCOR(INX(I+1),2))/CY(I,J1)
  235 CONTINUE
      DO 240 I=1,M
      RCOR(I,1)=RCOR(I,2)
      RCOR(I,2)=RCOR(I,3)
  240 CONTINUE
  241 CONTINUE
  230 CONTINUE
      IF(NB.EQ.NBLK) GO TO 246
C INFLUENCE MATRIX RX1
      DO 245 I=1,M2
      RINV(I1,I,NB)=RCOR(I+1,1)
  245 CONTINUE
C INFLUENCE MATRIX RX2
      DO 247 I=1,M2
      DUMMY1(I1,I)=RCOR(I+1,2)
  247 CONTINUE
      GO TO 249
  246 CONTINUE
C RESIDUAL MATRIX R FOR LAST BLOCK - RESIDUAL VECTORS COMPUTED ON
C   LAST INTERIOR ROW J=N-1.
      DO 248 I=2,M1
      DUMMY1(I1,I-1)=AX(I,N-1)*RCOR(INX(I-1),2)+AY(I,N-1)*RCOR(I,1)
     1+BB(I,N-1)*RCOR(I,2)+CX(I,N-1)*RCOR(INX(I+1),2)
      RINV(I1,I-1,NBLK)=DUMMY1(I1,I-1)
  248 CONTINUE
  249 CONTINUE
  215 CONTINUE
C INVERSE OF MATRIX RX2
      CALL MATINV(DUMMY1,B1,B2,M2) 
C RINV IS INVERSE OF RESIDUAL MATRIX FOR LAST BLOCK
      DO 276 J=1,M2
      DO 276 I=1,M2
      RINV(I,J,NBLK)=DUMMY1(I,J)
  276 CONTINUE
      IF(NB.EQ.NBLK) GO TO 275
C RINV1, INVERSE OF SX MATRIX, GIVEN BY INVERSE OF RX2 x RX1
      DO 260 J=1,M2
      DO 260 I=1,M2
      RINV1(I,J,NB)=0.0
      DO 261 K=1,M2
      RINV1(I,J,NB)=RINV1(I,J,NB)+DUMMY1(I,K)*RINV(K,J,NB)
  261 CONTINUE
  260 CONTINUE
C RINV IS INVERSE OF MATRIX RX2
      DO 270 J=1,M2
      DO 270 I=1,M2
      RINV(I,J,NB)=DUMMY1(I,J)
  270 CONTINUE
  275 CONTINUE
  205 CONTINUE
  300 CONTINUE
      RETURN
      END
      SUBROUTINE BSM2(AX,AY,BB,CX,CY,RINV,RINV1,RCOR,F,X,RTILDA,ERROR,
     1SUMF,IS,IE,INX,M,N,M1,N1,M2,N2,NBLK,NBLK1,IOUT,MX,NX)
C
      REAL*8 RINV,RINV1,RCOR,X,RTILDA
      REAL*8 F
      REAL*8 AX,AY,CX,CY,BB

!      REAL RINV,RINV1,RCOR,X,RTILDA
!      REAL F
!      REAL AX,AY,CX,CY,BB

      DIMENSION AX(MX,NX),AY(MX,NX),CX(MX,NX),CY(MX,NX),BB(MX,NX)
      DIMENSION X(MX,NX),F(MX,NX)
      DIMENSION RINV(M2,M2,NBLK),RINV1(M2,M2,NBLK1),RCOR(M,3)
      DIMENSION SUMF(NBLK),RTILDA(M2)
      DIMENSION IS(NBLK),IE(NBLK),INX(M)
C
C          ERROR VECTOR PROPAGATION METHOD
C
C  SOLUTION ITERATIONS
      NSTART=1
      DO 199 IT3=1,5
      IF(IOUT .EQ. 1) PRINT 700, IT3
  700 FORMAT(1X//,' SOLUTION ITERATION #',I4)
C
C     FORWARD SWEEP OF BLOCKS TO OBTAIN A PARTICULAR SOLUTION IN EACH
C     BLOCK. PARTICULAR SOLUTION SATIFIES THE BOUNDARY CONDITIONS, 
C     GIVEN AN ARBITARY VALUE AT END OF EACH BLOCK
C
      DO 200 NB=NSTART,NBLK
C FIRST ESTIMATE OF PARTICULAR SOLUTION IN INTERIOR OF EACH BLOCK
      ISP1=IS(NB)+1
      IEM2=IE(NB)-2
      DO 205 J=ISP1,IEM2
      DO 205 I=2,M1
      X(I,J+1)=(F(I,J)-AX(I,J)*X(INX(I-1),J)-AY(I,J)*X(I,J-1)
     1-BB(I,J)*X(I,J)-CX(I,J)*X(INX(I+1),J))/CY(I,J)
  205 CONTINUE
      IF(NB.EQ.NBLK) GO TO 200
C
C ITERATIONS TO CORRECT PARTICULAR SOLUTION WITH A RELATIVE RESIDUAL
C   ERROR .LE. 0.1
      DO 522 IT=1,10
      J1=IE(NB)-1
C ERROR VECTOR (INITIAL GUESS CHOICE - ESTIMATE OF PARTICULAR SOLUTION)
C  AT END OF BLOCK
      DO 215 I=2,M1
      RTILDA(I-1)=X(I,J1+1)-(F(I,J1)-AX(I,J1)*X(INX(I-1),J1)-AY(I,J1)
     1*X(I,J1-1)-BB(I,J1)*X(I,J1)-CX(I,J1)*X(INX(I+1),J1))/CY(I,J1)
  215 CONTINUE
C CHECK RELATIVE MAGNITUDE OF RESIDUAL ERROR (CY * ERROR VECTOR) AT
C  J=IE(NB)-1.
      A2=0.0
CCRM CORRECTION *CY, KS CORRECTION "CY(I+1"
      DO 216 I=1,M2
C      A2=A2+ABS(RTILDA(I)*CY(I+1,J1))

!      A2=A2+DABS(RTILDA(I)*CY(I+1,J1))

      A2=A2+ABS(RTILDA(I)*CY(I+1,J1))

  216 CONTINUE
      A3=A2/SUMF(NB)
      IF(IOUT .EQ. 1) THEN
      ITM1=IT-1
      PRINT 701, NB,ITM1
      PRINT 710, A2,A3
      ENDIF
  701 FORMAT(1X,' FORWARD SWEEP, BLOCK',I4,5X,' ITER=',I4)
  710 FORMAT(1X,' RESIDUAL ERROR =',1PE14.6,5X,'REL RESIDUAL =',1PE14.6)
      IF(A3.LE.0.1) GO TO 230
      DO 217 J=1,3
      DO 217 I=1,M
      RCOR(I,J)=0.0
  217 CONTINUE
C ERROR VECTOR AT SECOND ROW OF BLOCK
      DO 223 J=1,M2
      RCOR(J+1,2)=0.0
      DO 223 J1=1,M2
      RCOR(J+1,2)=RCOR(J+1,2)+RTILDA(J1)*RINV(J1,J,NB)
  223 CONTINUE
      IF(NB.EQ.1) GO TO 251
C ERROR VECTOR AT FIRST ROW OF BLOCK
      DO 225 J=2,M1
      RCOR(J,1)=0.0
      DO 225 K=2,M1
      RCOR(J,1)=RCOR(J,1)+RCOR(K,2)*RINV1(K-1,J-1,NB-1)
  225 CONTINUE
C CORRECT PARTICULAR SOLUTION ON FIRST ROW OF BLOCK
      DO 226 I=2,M1
      X(I,IS(NB))=X(I,IS(NB))+RCOR(I,1)
  226 CONTINUE
  251 CONTINUE
C FORWARD SWEEP OF ERROR VECTOR (HOMOGENEOUS SOLUTION) IN INTERIOR OF
C   BLOCK AND CORRECTING PARTICULAR SOLUTION IN INTERIOR
      CALL BSM3(AX,AY,BB,CX,CY,X,RCOR,IS(NB),IE(NB),NB,INX,M,N,M1,N1,
     1M2,N2,NBLK,NBLK1,MX,NX)
  522 CONTINUE
  230 CONTINUE
C
C RECOMPUTE GUESS VALUE FOR PARTICULAR SOLUTION AT END OF BLOCK
      J1=IE(NB)-1
      DO 220 I=2,M1
      X(I,J1+1)=(F(I,J1)-AX(I,J1)*X(INX(I-1),J1)-AY(I,J1)*X(I,J1-1)
     1      -BB(I,J1)*X(I,J1)-CX(I,J1)*X(INX(I+1),J1))/CY(I,J1)
  220 CONTINUE
  501 CONTINUE
  200 CONTINUE
      IF(IOUT .EQ. 1) PRINT 760
  760 FORMAT(10X)
C
C BACKWARD SWEEP OF BLOCKS TO OBTAIN SOLUTION
C
      DO 300 NB1=1,NBLK
      NB=NBLK -NB1+1
      ISP1=IS(NB)+1
      IEM2=IE(NB)-2
      J=IEM2
      IF(NB.EQ.NBLK) GO TO 502
C RECOMPUTE PARTICULAR SOLUTION AT ROW BEFORE END OF BLOCK J=IE(NB)-1
      DO 305 I=2,M1
      X(I,J+1)=(F(I,J)-AX(I,J)*X(INX(I-1),J)-AY(I,J)*X(I,J-1)
     1    -BB(I,J)*X(I,J)-CX(I,J)*X(INX(I+1),J))/CY(I,J)
  305 CONTINUE
  502 CONTINUE
C ITERATIONS TO REDUCE ERROR
      DO 552 IT=1,20
      IF(NB.EQ.NBLK) GO TO 317
C ERROR VECTOR (SOLUTION - PARTICULAR SOLUTION) AT END OF BLOCK, J=IE(NB)
      J1=IE(NB)-1
      DO 315 I=2,M1
      RTILDA(I-1)=X(I,J1+1)-(F(I,J1)-AX(I,J1)*X(INX(I-1),J1)-AY(I,J1)
     1*X(I,J1-1)-BB(I,J1)*X(I,J1)-CX(I,J1)*X(INX(I+1),J1))/CY(I,J1)
  315 CONTINUE
      GO TO 318
  317 CONTINUE
C RESIDUAL VECTOR FOR THE SOLUTION ERROR AT LAST INTERIOR ROW J=N-1.
C I.E. THE NEGATIVE OF THE RESIDUAL VECTOR FOR THE PARTICULAR SOLUTION.
C NOTE: DIRICHLET B.V. AT J=N HAS BEEN FOLDED INTO FORCING F(I,N-1)
      DO 319 I=2,M1
      RTILDA(I-1)=F(I,N-1)-(AX(I,N-1)*X(INX(I-1),N-1)+AY(I,N-1)
     1    *X(I,N-2)+BB(I,N-1)*X(I,N-1)+CX(I,N-1)*X(INX(I+1),N-1))
  319 CONTINUE
  318 CONTINUE
C CHECK MAGNITUDE OF RELATIVE ERROR
      A2=0.0
CCRM CORRECTION FOR NB .NE. NBLK
      IF (NB.EQ.NBLK)GO TO 3180
      DO 3177 I=1,M2
C      A2=A2+ABS(RTILDA(I)*CY(I+1,J1))

!      A2=A2+DABS(RTILDA(I)*CY(I+1,J1))

      A2=A2+ABS(RTILDA(I)*CY(I+1,J1))

 3177 CONTINUE
      GO TO 3178
 3180 CONTINUE
      DO 316 I=1,M2
C      A2=A2+ABS(RTILDA(I))

!      A2=A2+DABS(RTILDA(I))

      A2=A2+ABS(RTILDA(I))

  316 CONTINUE
 3178 CONTINUE
      A3=A2/SUMF(NB)
      IF(IOUT .EQ. 1) THEN
      ITM1=IT-1
      PRINT 702, NB,ITM1
  702 FORMAT(1X,' BACKWARD SWEEP, BLOCK =',I4,5X,' ITER =',I4)
      PRINT 710, A2, A3
      ENDIF
      IF(A3.LE.ERROR) GO TO 555
      DO 320 J=1,3
      DO 320 I=1,M
      RCOR(I,J)=0.0
  320 CONTINUE
C ERROR VECTOR AT SECOND ROW OF BLOCK
      DO 324 J=1,M2
      RCOR(J+1,2)=0.0
      DO 324 J1=1,M2
      RCOR(J+1,2)=RCOR(J+1,2)+RTILDA(J1)*RINV(J1,J,NB)
  324 CONTINUE
      IF(NB.EQ.1) GO TO 551
C ERROR VECTOR AT FIRST ROW OF BLOCK (FOR BLOCK .NE. 1)
      DO 325 J=2,M1
      RCOR(J,1)=0.0
      DO 325 K=2,M1
      RCOR(J,1)=RCOR(J,1)+RCOR(K,2)*RINV1(K-1,J-1,NB-1)
  325 CONTINUE
C SOLUTION AT FIRST ROW OF BLOCK (FOR BLOCK .NE. 1)
      DO 326 I=2,M1
      X(I,IS(NB))=X(I,IS(NB))+RCOR(I,1)
  326 CONTINUE
  551 CONTINUE
C FORWARD SWEEP OF HOMOGENEOUS SOLUTION CORRECTING PARTICULAR SOLUTION
C   IN INTERIOR
      CALL BSM3(AX,AY,BB,CX,CY,X,RCOR,IS(NB),IE(NB),NB,INX,M,N,M1,N1,
     1M2,N2,NBLK,NBLK1,MX,NX)
  552 CONTINUE
  555 CONTINUE
  300 CONTINUE
      IF(IOUT .EQ. 1) PRINT 761, IT3
  761 FORMAT(1X/,' END OF ITERATION #',I4/)
C
C ERRORS ACCUMULATE AT END BOUNDARIES OF INTERIOR BLOCKS, USUALLY
C  LARGEST FOR LAST INTERIOR BLOCK
C
      A4=0.0
      DO 350 NB=1,NBLK
C ERROR VECTOR AT SECOND INTERIOR ROW OF BLOCK, J=IS(NB)+2
CCKS      J1=IE(1)
      J1=IS(NB)+1
      DO 330 I=2,M1
      RTILDA(I-1)=X(I,J1+1)-(F(I,J1)-AX(I,J1)*X(INX(I-1),J1)-AY(I,J1)
     1  *X(I,J1-1)-BB(I,J1)*X(I,J1)-CX(I,J1)*X(INX(I+1),J1))/CY(I,J1)
  330 CONTINUE
C CHECK RESIDUAL ERROR (CY X ERROR VECTOR) AT FIRST INTERIOR ROW
C OF BLOCK, J=IS(NB)+1
      A2=0.0
CCKS  CORRECTION *CY
      DO 332 I=1,M2
C      A2=A2+ABS(RTILDA(I)*CY(I+1,J1))

!      A2=A2+DABS(RTILDA(I)*CY(I+1,J1))

      A2=A2+ABS(RTILDA(I)*CY(I+1,J1))

  332 CONTINUE
      IF(NB.NE.1) A3=A2/SUMF(NB-1)
      IF(NB.EQ.1) A3=A2/SUMF(1)
      A4=AMAX1(A4,A3)
      IF(IOUT .EQ. 1) THEN
      PRINT 720, NB
  720 FORMAT(1X,' ERROR AT START OF BLOCK#',I4)
      PRINT 710, A2, A3
      ENDIF
  350 CONTINUE
C
      IF(A4.LE.ERROR) GO TO 201
      NSTART=2
C
  199 CONTINUE
  201 CONTINUE
C
      RETURN
      END
      SUBROUTINE BSM3(AX,AY,BB,CX,CY,X,RCOR,IS,IE,NB,INX,M,N,M1,N1,
     1M2,N2,NBLK,NBLK1,MX,NX)

      REAL*8 X,RCOR
      REAL*8 AX,AY,CX,CY,BB

!      REAL X,RCOR
!      REAL AX,AY,CX,CY,BB

      DIMENSION AX(MX,NX),AY(MX,NX),CX(MX,NX),CY(MX,NX),BB(MX,NX)
      DIMENSION RCOR(M,3),X(MX,NX)
      DIMENSION INX(M)
C
C      *****    HOMOGENEOUS MARCHING OF SOLUTION ERROR **********
C
C    SOLUTION ERROR SATISFIES THE HOMOGENEOUS EQUATIONS (F=0)
C
C CORRECT SOLUTION AT SECOND ROW OF BLOCK
      DO 135 I=2,M1
      X(I,IS+1)=X(I,IS+1)+RCOR(I,2)
  135 CONTINUE
      ISP1=IS+1
      IEM2=IE-2
C MARCHING ERROR VECTOR THROUGH INTERIOR OF BLOCK AND CORRECTING SOLUTION
      DO 140 J=ISP1,IEM2
      DO 145 I=2,M1
      RCOR(I,3)=(-AX(I,J)*RCOR(INX(I-1),2)-AY(I,J)*RCOR(I,1)
     1  -BB(I,J)*RCOR(I,2)-CX(I,J)*RCOR(INX(I+1),2))/CY(I,J)
  145 CONTINUE
      DO 150 I=2,M1
      X(I,J+1)=X(I,J+1)+RCOR(I,3)
      RCOR(I,1)=RCOR(I,2)
      RCOR(I,2)=RCOR(I,3)
  150 CONTINUE
  140 CONTINUE
      RETURN
      END
      SUBROUTINE MATINV(B,B1,B2,M)
      IMPLICIT REAL*8(A-H,O-Z)    
      DIMENSION B(M,M)
      DIMENSION B1(M),B2(M)
C  MATRIX INVERSION USING GAUSSIAN ELIMINATION TO SOLVE
C      B x(i)  = e(i), 
C  for a set of unit column vectors e(i)(in which ith element is equal to one)
C    ie  B X = I,  I the IDENTITY MATRIX and X the MATRIX INVERSE
C
C  In the method, matrix B is modified by row reduction to upper
C triangular form, with ones on all diagonal elements except the last and
C zeros below the diagonal. The corresponding row operations on the 
C identity matrix I result in a lower triangular matrix. To save space,
C the result of the row operations on the identity matrix are stored
C in matrix B, on and below the diagonal, not including the last diagonal
C element. Back substitition produces the inverse matrix in B.
C
C ROW REDUCTION OF MATRIX TO ZERO BELOW DIAGONAL
C
      M1=M-1
      DO 110 I=1,M1
C SCALE FACTOR FOR ITH ROW
      B1(1)=1.0/B(I,I)
C RESET DIAGONAL ELEMENT TO 1
      B(I,I)=1.0
C SCALE ITH ROW GIVING 1 IN DIAGONAL AND SAVING SCALING FACTOR IN DIAGONAL
C POSITION
      DO 112 J=1,M
      B(I,J)=B(I,J)*B1(1)
  112 CONTINUE
      IP1=I+1
C MULTIPLICATION FACTOR FOR REDUCTION OF ROWS BELOW ITH ROW
      DO 120 I1=IP1,M
      B1(I1)=B(I1,I)
  120 CONTINUE
C RESET ELEMENTS BELOW DIAGONAL OF ITH ROW TO ZERO TO PROVIDE STORAGE SPACE
      DO 125 I1=IP1,M
      B(I1,I)=0.0
  125 CONTINUE
C ITH ROW
      DO 127 J=1,M
      B2(J)=B(I,J)
  127 CONTINUE
C REDUCE ALL ELEMENTS BELOW DIAGONAL OF ITH ROW TO ZERO, SAVING 
C ROW MULTI. OPERATIONS ON IDENTITY MATRIX IN SPACE BELOW DIAGONAL
      DO 135 I1=IP1,M
      DO 135 J=1,M
      B(I1,J)=B(I1,J)-B1(I1)*B2(J)
  135 CONTINUE
  110 CONTINUE
C
C BACK SUBSTITUTION
C
C SCALING FACTOR FOR LAST ROW
      B1(1)=1.0/B(M,M)
C REPLACE DIAGONAL ELEMENT OF INPUT MATRIX WITH LAST ELEMENT OF DIAGONAL
C  OF IDENTIY MATRIX
      B(M,M)=1.0
C DIVIDE LAST ROW OF MODIFIED IDENTITY MATRIX BY SCALING FACTOR TO SOLVE 
C FOR LAST ROW
      DO 140 J=1,M
      B(M,J)=B(M,J)*B1(1)
  140 CONTINUE
C
C BACK SUBSTITUTION FOR REMAINING ROWS 1 TO M-1,
C BY REDUCING TO ZERO THE ELEMENTS ABOVE DIAG FOR DIAG ELEMENTS 2 TO M.
C
      DO 150 I=2,M
C SAVE ROW MULTI. FACTORS FOR REDUCTION TO ZERO ABOVE DIAG IN ITH COLUMN
      DO 155 I2=1,I
      B1(I2)=B(I2,I)
  155 CONTINUE
C PUT BACK ZEROS ABOVE DIAG IN ITH COLUMN OF MODIFIED IDENTIY MATRIX
      IM1=I-1
      DO 156 I2=1,IM1
      B(I2,I)=0.0
  156 CONTINUE
C ITH ROW OF MODIFIED U DIAG MATRIX AND MODIFIED L DIAG IDENTITY MATRIX
      DO 157 J=1,M
      B2(J)=B(I,J)
  157 CONTINUE
C REDUCE ELEMENTS ABOVE ITH DIAG ELEMENT TO ZERO IN ROWS 1 TO I-1
      IM1=I-1
      DO 160 I2=1,IM1
      DO 160 J=1,M
      B(I2,J)=B(I2,J)-B1(I2)*B2(J)
  160 CONTINUE
  150 CONTINUE
      RETURN
      END

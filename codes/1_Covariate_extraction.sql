WITH
  T1 AS( -- Filter out MICU/SICU patitents over age 18yo
  SELECT
    icu.subject_id,
    icu.hadm_id,
    icu.stay_id,
    icu.intime,
    icu.los
  FROM
    `physionet-data.mimiciv_icu.icustays` icu
  LEFT JOIN
    `physionet-data.mimiciv_derived.age` a
  ON
    icu.subject_id = a.subject_id
  WHERE
    a.age >= 18 AND( first_careunit = 'Surgical Intensive Care Unit (SICU)'
      OR first_careunit = 'Medical/Surgical Intensive Care Unit (MICU/SICU)' ) ),
  T2 AS( -- Rank the ICU stay sequence by the admission time
  SELECT
    DISTINCT subject_id,
    hadm_id,
    stay_id,
    intime,
    los,
    DENSE_RANK() OVER(PARTITION BY subject_id ORDER BY intime) AS icu_s
  FROM
    T1 ),
  T3 AS( -- Pick sequence = 1 (first admission in ICU)
  SELECT
    *
  FROM
    T2
  WHERE
    icu_s = 1 ),
  T4 AS( -- Connect with inputevents
  SELECT
    T3.subject_id,
    T3.hadm_id,
    T3.stay_id,
    T3.los,
    inp.starttime,
    inp.endtime,
    inp.itemid,
    inp.amount,
    inp.amountuom,
    inp.ordercategoryname
  FROM
    `physionet-data.mimiciv_icu.inputevents` inp
  JOIN
    T3
  ON
    inp.stay_id = T3.stay_id ),
  T5 AS( -- Patitents that admit Enoxaparin
  SELECT
    DISTINCT subject_id,
    hadm_id,
    stay_id,
    amount,
    amountuom,
    'Enoxaparin' AS input
  FROM
    T4
  WHERE
    itemid = 225906
    AND ordercategoryname = '11-Prophylaxis (Non IV)' ),
  T6 AS( -- Patients that admit Heparin
  SELECT
    DISTINCT subject_id,
    hadm_id,
    stay_id,
    amount,
    amountuom,
    'Heparin' AS input
  FROM
    T4
  WHERE
    itemid = 225975
    AND ordercategoryname = '11-Prophylaxis (Non IV)' ),
  target_subjects AS( -- Combine T5 & T6 (Enoxaparin and Heparin) and drop subjects that take both Enoxaparin and Heparin
  SELECT
    *
  FROM (
    SELECT
      *
    FROM
      T5
    WHERE
      subject_id NOT IN(
      SELECT
        subject_id
      FROM
        T6 ))
  UNION ALL (
    SELECT
      *
    FROM
      T6
    WHERE
      subject_id NOT IN(
      SELECT
        subject_id
      FROM
        T5 )) ),
  T7 AS( -- T7 & T8: The use of antithrombotic agents & vasopressor
  SELECT
    tar.subject_id,
    tar.hadm_id,
    tar.stay_id,
    e.event_txt,
    tar.input,
    CASE
      WHEN (e.medication = 'Aspirin' OR -- List of antithrombotic agents
            e.medication = 'Clopidogrel' OR e.medication = 'Prasugrel' OR 
            e.medication = 'Ticagrelor' OR e.medication = 'Dipyridamole' OR 
            e.medication = 'Eptifibatide' OR e.medication = 'Apixaban' OR 
            e.medication = 'Rivaroxaban' OR e.medication = 'Edoxaban' OR 
            e.medication = 'Dabigatran' OR e.medication = 'Warfarin' )AND e.medication IS NOT NULL THEN 1
    ELSE
    0
    END AS if_med1,
    CASE
      WHEN (e.medication = 'Vasopressin' OR -- List of vasopressor
            LOWER(e.medication) LIKE '%norepinephrine%' OR 
            LOWER(e.medication) LIKE '%dopamine%' OR 
            LOWER(e.medication) LIKE '%epinephrine%') AND e.medication IS NOT NULL THEN 1
    ELSE
    0
    END AS if_med2
  FROM
    target_subjects tar
  LEFT JOIN
    `physionet-data.mimiciv_hosp.emar` e
  ON
    tar.subject_id = e.subject_id
    AND tar.hadm_id = e.hadm_id
  ORDER BY
    subject_id,
    hadm_id),
  T8 AS(
  SELECT
    subject_id,
    hadm_id,
    stay_id,
    input,
    SUM(dm1) AS if_antithrombotic_agents,
    SUM(dm2) AS if_vasopressin
  FROM (
    SELECT
      DISTINCT subject_id,
      hadm_id,
      stay_id,
      input,
      CASE
        WHEN (event_txt IS NOT NULL AND event_txt = 'Administered' AND if_med1 = 1 AND if_med1 IS NOT NULL) THEN 1
      ELSE
      0
    END
      AS dm1,
      CASE
        WHEN (event_txt IS NOT NULL AND event_txt = 'Administered' AND if_med2 = 1 AND if_med2 IS NOT NULL) THEN 1
      ELSE
      0
    END
      AS dm2,
    FROM
      T7)
  GROUP BY
    subject_id,
    hadm_id,
    stay_id,
    input ),
  T9 AS( -- Height table
  SELECT
    T8.subject_id,
    T8.hadm_id,
    T8.stay_id,
    input,
    if_antithrombotic_agents,
    if_vasopressin,
    height
  FROM
    T8
  LEFT JOIN
    `physionet-data.mimiciv_derived.height` h
  ON
    T8.subject_id = h.subject_id
    AND T8.stay_id = h.stay_id),
  T10 AS(
  SELECT
    *
  FROM
    T9
  LEFT JOIN
    `physionet-data.mimiciv_derived.weight_durations` w
  ON
    T9.stay_id = w.stay_id ),
  T11 AS( -- BMI table
  SELECT
    t.subject_id,
    t.input,
    o.chartdate,
    o.seq_num,
    CAST(o.result_value AS FLOAT64) AS bmi
  FROM
    target_subjects t
  LEFT JOIN
    `physionet-data.mimiciv_hosp.omr` o
  ON
    t.subject_id = o.subject_id
  WHERE
    o.result_name = 'BMI (kg/m2)' ),
  T12 AS( -- Subjects' average weight
  SELECT
    t.subject_id,
    t.hadm_id,
    t.stay_id,
    t.input,
    ROUND(AVG(w.weight),2) AS avgw
  FROM
    target_subjects t
  LEFT JOIN
    `physionet-data.mimiciv_derived.weight_durations` w
  ON
    t.stay_id = w.stay_id
  GROUP BY
    t.subject_id,
    t.hadm_id,
    t.stay_id,
    t.input ),
  T13 AS( -- Subject's average platelet level
  SELECT
    t.subject_id,
    t.hadm_id,
    t.stay_id,
    t.input,
    ROUND(AVG(cbc.platelet),2) AS avg_pl
  FROM
    target_subjects t
  LEFT JOIN
    `physionet-data.mimiciv_derived.complete_blood_count` cbc
  ON
    t.subject_id = cbc.subject_id
    AND t.hadm_id = cbc.hadm_id
  GROUP BY
    t.subject_id,
    t.hadm_id,
    t.stay_id,
    t.input ),
  T14 AS( -- Subject's average creatine level
  SELECT
    t.subject_id,
    t.hadm_id,
    t.stay_id,
    t.input,
    ROUND(AVG(kc.creat),2) AS avg_creat
  FROM
    target_subjects t
  LEFT JOIN
    `physionet-data.mimiciv_derived.kdigo_creatinine` kc
  ON
    t.stay_id = kc.stay_id
    AND t.hadm_id = kc.hadm_id
  GROUP BY
    t.subject_id,
    t.hadm_id,
    t.stay_id,
    t.input ),
  T15 AS( -- Subjects' first day sofa score
  SELECT
    t.subject_id,
    t.hadm_id,
    t.stay_id,
    t.input,
    AVG(fsofa.SOFA) AS first_day_sofa
  FROM
    target_subjects t
  LEFT JOIN
    `physionet-data.mimiciv_derived.first_day_sofa` fsofa
  ON
    t.subject_id = fsofa.subject_id
    AND t.hadm_id = fsofa.hadm_id
    AND t.stay_id = fsofa.stay_id
  GROUP BY
    t.subject_id,
    t.hadm_id,
    t.stay_id,
    t.input ),
  T16 AS( -- Comorbidities
  SELECT
    t.subject_id,
    t.hadm_id,
    ch.age_score,
    ch.myocardial_infarct,
    ch.congestive_heart_failure,
    ch.peripheral_vascular_disease,
    ch.cerebrovascular_disease,
    ch.chronic_pulmonary_disease,
    ch.peptic_ulcer_disease,
    ch.diabetes_with_cc,
    ch.diabetes_without_cc,
    ch.renal_disease,
    ch.malignant_cancer,
    ch.severe_liver_disease,
    ch.metastatic_solid_tumor,
    ch.charlson_comorbidity_index
  FROM
    target_subjects t
  LEFT JOIN
    `physionet-data.mimiciv_derived.charlson` ch
  ON
    t.subject_id = ch.subject_id
    AND t.hadm_id = ch.hadm_id ),
  T17 AS( -- Get ventilation status for each subject, code invasive as 2, non-invasive as 1 and none ventilation as 0
  SELECT
    t.subject_id,
    t.hadm_id,
    t.stay_id,
    v.starttime,
    v.endtime,
    CASE
      WHEN (v.ventilation_status = 'InvasiveVent' OR v.ventilation_status = 'Tracheostomy') THEN 2
      WHEN (v.ventilation_status = 'None'
      OR v.ventilation_status IS NULL) THEN 0
    ELSE
    1
  END
    AS ventilation_st
  FROM
    target_subjects t
  LEFT JOIN
    `physionet-data.mimiciv_derived.ventilation` v
  ON
    t.stay_id = v.stay_id )
SELECT
  *
FROM
  T17

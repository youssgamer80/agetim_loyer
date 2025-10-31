class MoisLoyer {
  final int annee;
  final int mois;
  final double montant;
  final double montantPaye;
  final double reste;

  MoisLoyer({
    required this.annee,
    required this.mois,
    required this.montant,
    required this.montantPaye,
    required this.reste,
  });

  String get nomMois {
    const mois = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return mois[this.mois - 1];
  }

  String get periode => '$nomMois $annee';

  bool get estCompletementPaye => reste == 0;

  Map<String, dynamic> toJson() {
    return {
      'annee': annee,
      'mois': mois,
      'montant': montant,
      'montant_paye': montantPaye,
      'reste': reste,
    };
  }

  factory MoisLoyer.fromJson(Map<String, dynamic> json) {
    return MoisLoyer(
      annee: json['annee'] as int? ?? DateTime.now().year, // Sécurisé (default: année courante)
      mois: json['mois'] as int? ?? DateTime.now().month, // Sécurisé (default: mois courant)
      montant: (json['montant'] as num?)?.toDouble() ?? 0.0, // Sécurisé
      montantPaye: (json['montant_paye'] as num?)?.toDouble() ?? 0.0, // Sécurisé
      reste: (json['reste'] as num?)?.toDouble() ?? 0.0, // Sécurisé
    );
  }
}

class RepartitionPaiement {
  final List<MoisLoyer> moisPayes;
  final double montantTotal;
  final double montantRestant;
  final String periodeDebut;
  final String periodeFin;

  RepartitionPaiement({
    required this.moisPayes,
    required this.montantTotal,
    required this.montantRestant,
    required this.periodeDebut,
    required this.periodeFin,
  });

  String genererResume() {
    StringBuffer resume = StringBuffer();

    for (var mois in moisPayes) {
      if (mois.montantPaye > 0) {
        if (mois.estCompletementPaye) {
          resume.writeln('${mois.periode}: ${_formatMontant(mois.montantPaye)} (Soldé)');
        } else {
          resume.writeln('${mois.periode}: ${_formatMontant(mois.montantPaye)} (Reste: ${_formatMontant(mois.reste)})');
        }
      }
    }

    return resume.toString().trim();
  }

  String genererResumeSMS() {
    StringBuffer sms = StringBuffer();

    for (var mois in moisPayes) {
      if (mois.montantPaye > 0) {
        if (mois.estCompletementPaye) {
          sms.write('${mois.periode}: ${_formatMontant(mois.montantPaye)} (Solde), ');
        } else {
          sms.write('${mois.periode}: ${_formatMontant(mois.montantPaye)} (Reste: ${_formatMontant(mois.reste)}), ');
        }
      }
    }

    String result = sms.toString();
    if (result.endsWith(', ')) {
      result = result.substring(0, result.length - 2);
    }

    return result;
  }

  String _formatMontant(double montant) {
    return '${montant.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')}F';
  }

  int get nombreMoisPayes => moisPayes.where((m) => m.montantPaye > 0).length;
  int get nombreMoisSoldes => moisPayes.where((m) => m.estCompletementPaye).length;

  Map<String, dynamic> toJson() {
    return {
      'mois_payes': moisPayes.map((m) => m.toJson()).toList(),
      'montant_total': montantTotal,
      'montant_restant': montantRestant,
      'periode_debut': periodeDebut,
      'periode_fin': periodeFin,
    };
  }
}
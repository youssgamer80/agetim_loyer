import '../models/paiement_repartition.dart';

class RepartitionService {
  /// Calcule la répartition d'un paiement sur les mois de loyer dus
  ///
  /// [montantDu] : Montant total dû avant le paiement
  /// [loyerMensuel] : Montant du loyer mensuel
  /// [montantPaye] : Montant payé par le locataire
  /// [dateReference] : Date de référence pour le calcul (généralement aujourd'hui)
  RepartitionPaiement calculerRepartition({
    required double montantDu,
    required double loyerMensuel,
    required double montantPaye,
    DateTime? dateReference,
  }) {
    dateReference ??= DateTime.now();

    // Calculer le nombre de mois de retard
    int nombreMoisDus = (montantDu / loyerMensuel).ceil();

    // Créer la liste des mois dus
    List<MoisLoyer> moisDus = [];
    DateTime dateDebut = DateTime(
      dateReference.year,
      dateReference.month - nombreMoisDus,
      1,
    );

    for (int i = 0; i < nombreMoisDus; i++) {
      DateTime moisCourant = DateTime(
        dateDebut.year,
        dateDebut.month + i,
        1,
      );

      moisDus.add(MoisLoyer(
        annee: moisCourant.year,
        mois: moisCourant.month,
        montant: loyerMensuel,
        montantPaye: 0,
        reste: loyerMensuel,
      ));
    }

    // Ajouter le mois en cours si nécessaire
    bool moisCourantInclus = moisDus.any((m) =>
    m.annee == dateReference?.year && m.mois == dateReference?.month
    );

    if (!moisCourantInclus) {
      moisDus.add(MoisLoyer(
        annee: dateReference.year,
        mois: dateReference.month,
        montant: loyerMensuel,
        montantPaye: 0,
        reste: loyerMensuel,
      ));
    }

    // Répartir le montant payé sur les mois dus
    double montantRestantADistribuer = montantPaye;
    List<MoisLoyer> moisPayes = [];

    for (var mois in moisDus) {
      if (montantRestantADistribuer <= 0) {
        // Plus d'argent à distribuer
        moisPayes.add(mois);
        continue;
      }

      double montantPourCeMois = montantRestantADistribuer >= mois.montant
          ? mois.montant
          : montantRestantADistribuer;

      moisPayes.add(MoisLoyer(
        annee: mois.annee,
        mois: mois.mois,
        montant: mois.montant,
        montantPaye: montantPourCeMois,
        reste: mois.montant - montantPourCeMois,
      ));

      montantRestantADistribuer -= montantPourCeMois;
    }

    // Calculer le nouveau montant dû
    double nouveauMontantDu = moisPayes.fold(0.0, (sum, mois) => sum + mois.reste);

    String periodeDebut = moisPayes.first.periode;
    String periodeFin = moisPayes.last.periode;

    return RepartitionPaiement(
      moisPayes: moisPayes,
      montantTotal: montantPaye,
      montantRestant: nouveauMontantDu,
      periodeDebut: periodeDebut,
      periodeFin: periodeFin,
    );
  }

  /// Génère un message détaillé pour le SMS
  String genererMessageSMS({
    required String nomLocataire,
    required String codeLogement,
    required RepartitionPaiement repartition,
    required String numeroRecu,
    required String dateHeureRecu,
    required String codeUnique,
    String? nomAgent,
  }) {
    StringBuffer message = StringBuffer();

    message.writeln('AGETIM - Confirmation de Paiement');
    message.writeln('');
    message.writeln('Cher(e) $nomLocataire,');
    message.writeln('');
    message.writeln('Paiement enregistre avec succes.');
    message.writeln('');
    message.writeln('Montant total: ${_formatMontant(repartition.montantTotal)}');
    message.writeln('Logement: $codeLogement');
    message.writeln('');
    message.writeln('REPARTITION DU PAIEMENT:');
    message.writeln('------------------------');

    for (var mois in repartition.moisPayes) {
      if (mois.montantPaye > 0) {
        if (mois.estCompletementPaye) {
          message.writeln('${mois.periode}: ${_formatMontant(mois.montantPaye)} ✓');
        } else {
          message.writeln('${mois.periode}: ${_formatMontant(mois.montantPaye)}');
          message.writeln('  Reste a payer: ${_formatMontant(mois.reste)}');
        }
      }
    }

    message.writeln('');

    if (repartition.montantRestant > 0) {
      message.writeln('SOLDE RESTANT: ${_formatMontant(repartition.montantRestant)}');
      message.writeln('');
    } else {
      message.writeln('Compte SOLDE ✓');
      message.writeln('');
    }

    message.writeln('Recu N°: $numeroRecu');
    message.writeln('Date: $dateHeureRecu');
    message.writeln('Code: $codeUnique');

    if (nomAgent != null) {
      message.writeln('Agent: $nomAgent');
    }

    message.writeln('');
    message.writeln('Merci pour votre confiance.');
    message.writeln('AGETIM Immobilier');

    return message.toString();
  }

  String _formatMontant(double montant) {
    return '${montant.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]} '
    )}F';
  }
}